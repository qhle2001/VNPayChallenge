//
//  PhotoListViewController.swift
//  VNPayChallange
//
//  Created by Le Quang Hung on 1/10/25.
//


import UIKit

final class PhotoListViewController: UIViewController {

    private let searchBar = SearchBarView()
    private let tableView = UITableView()
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    private let viewModel = PhotoListViewModel()
    private var isLoadingMore: Bool = false
    private var currentPage: Int = 1
    private var isSearching: Bool = false
    private var searchKeyword: String?

    // Data
    private var photosOriginal: [Photo] = []
    private var photosFiltered: [Photo] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        print("viewđiload")
        networkMonitorStart()
        tapGestureDismisKeyboard()
        setupUI()
        setupConstraints()
        setupTableView()
        setupSearch()
        bindViewModel()
        startFetchPhotos()
        UIApplication.shared.isIdleTimerDisabled = false
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NetworkMonitor.shared.stopMonitoring()
    }
    
    // MARK: - Gesture and dismiss keyboard
    private func tapGestureDismisKeyboard() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - Bind viewmodel
    private func bindViewModel() {
        viewModel.didUpdatePhotos = { [weak self] in
            guard let self = self else { return }
            print("Fetch successfully, the number of photos: \(self.viewModel.photos.count)")

            if self.viewModel.photos.count == 0 {
                self.currentPage -= 1
            } else {
                self.photosOriginal.append(contentsOf: self.viewModel.photos)
                if self.isSearching, let keyword = self.searchKeyword {
                    self.filterPhotos(with: keyword, isSearching: self.isSearching)
                } else {
                    self.photosFiltered.append(contentsOf: self.viewModel.photos)
                    self.tableView.reloadData()
                }
            }
            self.isLoadingMore = false
            self.activityIndicator.stopAnimating()          
        }

        viewModel.didFailWithError = { [weak self] error, didRetry in
            print("Fetch error: \(error.localizedDescription) \(didRetry)")
            self?.isLoadingMore = false
            self?.activityIndicator.stopAnimating()

            if didRetry{
                AlertHelper.shared.showError(
                    title: "Error",
                    message: error.localizedDescription,
                    retryHandler: {
                        self?.startFetchPhotos()
                    },
                    onCancel: {
                        self?.currentPage -= 1
                    }
                )
            } else {
                self?.currentPage -= 1
                AlertHelper.shared.showError(
                    title: "Error",
                    message: error.localizedDescription
                )
            }
        }
    }

    // MARK: - Network Monitor
    private func networkMonitorStart() {
        NetworkMonitor.shared.onStatusChange = { [weak self ] status in 
            guard let self = self else { return }

            switch status {
            case .noConnection:
                AlertHelper.shared.showError(
                    type: .connection,
                    title: "Connection Error",
                    message: "No Internet connection. Please check your Wi-Fi or mobile data."
                )
            case .unavailable:
                AlertHelper.shared.showError(
                    type: .connection,
                    title: "Connection Error",
                    message: "Network connection unavailable. Please check your Internet access."
                )
            case .connected:
                print("Internet Available.")
                AlertHelper.shared.dismissAlert(for: .connection)
            case .other:
                print("Abnormal feedback network.")
            }
        }

        NetworkMonitor.shared.startMonitoring()
    }

    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .white
        view.addSubview(searchBar)
        view.addSubview(tableView)
        view.addSubview(activityIndicator)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        searchBar.translatesAutoresizingMaskIntoConstraints = false
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            searchBar.heightAnchor.constraint(equalToConstant: 36),

            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    // MARK: - FetchPhotos
    private func startFetchPhotos(){
        activityIndicator.startAnimating()
        viewModel.loadPhotos(currentPage)
    }

    // MARK: - TableView Setup
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(PhotoCell.self, forCellReuseIdentifier: "PhotoCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 500
    }

    // MARK: - Search Setup
    private func setupSearch() {
        searchBar.onSearchAction { [weak self] query, isSearching in
            self?.isSearching = isSearching
            self?.searchKeyword = query
            self?.filterPhotos(with: query, isSearching: isSearching)
        }
    }

    // MARK: - Filter
    private func filterPhotos(with query: String?, isSearching: Bool) {
        guard let query = query, !query.isEmpty else {
            photosFiltered = photosOriginal
            tableView.reloadData()
            return
        }

        photosFiltered = photosOriginal.filter { photo in
            photo.author.lowercased().contains(query.lowercased()) ||
            "\(photo.id)".contains(query)
        }
        tableView.reloadData()
    }
}

// MARK: - UITableViewDataSource & Delegate
extension PhotoListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return photosFiltered.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PhotoCell", for: indexPath) as? PhotoCell else {
            return UITableViewCell()
        }
        let photo = photosFiltered[indexPath.row]
        cell.configure(with: photo)
        return cell
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let frameHeight = scrollView.frame.size.height
        
        if offsetY > contentHeight - frameHeight {
            loadMorePhotosIfNeeded()
        }
    }
    
    private func loadMorePhotosIfNeeded(){
        guard !isLoadingMore else { return }
        print("Scrolled almost all the way down the table")
        currentPage += 1
        isLoadingMore = true
        startFetchPhotos()
    }
}
