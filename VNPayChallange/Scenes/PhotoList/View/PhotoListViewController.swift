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

    // Data
    private var photosOriginal: [Photo] = []
    private var photosFiltered: [Photo] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupTableView()
        setupSearch()
        fetchPhotos()
    }

    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .white
        view.addSubview(searchBar)
        view.addSubview(tableView)
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
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        
        
        
    }

    // MARK: - TableView Setup
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(PhotoCell.self, forCellReuseIdentifier: "PhotoCell")
        tableView.rowHeight = 100
    }

    // MARK: - Search Setup
    private func setupSearch() {
        searchBar.onSearchAction { [weak self] query in
            self?.filterPhotos(with: query)
        }
    }

    // MARK: - Filter
    private func filterPhotos(with query: String) {
        if query.isEmpty {
            photosFiltered = photosOriginal
        } else {
            photosFiltered = photosOriginal.filter { photo in
                photo.author.lowercased().contains(query.lowercased()) ||
                "\(photo.id)".contains(query)
            }
        }
        tableView.reloadData()
    }

    // MARK: - Fetch Photos
    private func fetchPhotos() {
        // Gọi API, gán dữ liệu vào photosOriginal + photosFiltered
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
}
