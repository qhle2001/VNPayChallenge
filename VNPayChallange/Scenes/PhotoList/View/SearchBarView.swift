//
//  SearchBarView.swift
//  VNPayChallange
//
//  Created by Le Quang Hung on 1/10/25.
//

import UIKit

final class SearchBarView: UIView {
    let textField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Search author or id"
        tf.borderStyle = .roundedRect
        tf.returnKeyType = .search
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    let searchButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Search", for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    private var onSearch: ((String?, Bool) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
        setupActions()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupConstraints()
        setupActions()
    }
    
    private func setupUI() {
        backgroundColor = .white
        layer.borderWidth = 1
        layer.borderColor = UIColor.gray.cgColor
        layer.cornerRadius = 8
        
        addSubview(textField)
        addSubview(searchButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: topAnchor),
            textField.leadingAnchor.constraint(equalTo: leadingAnchor),
            textField.bottomAnchor.constraint(equalTo: bottomAnchor),
            textField.trailingAnchor.constraint(equalTo: searchButton.leadingAnchor, constant: -8), // ← thêm

            searchButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            searchButton.centerYAnchor.constraint(equalTo: textField.centerYAnchor),
            searchButton.widthAnchor.constraint(equalToConstant: 70)
        ])
    }
    
    private func setupActions() {
        textField.delegate = self
        searchButton.addTarget(self, action: #selector(didTapSearch), for: .touchUpInside)
    }
    
    func onSearchAction(_ callback: @escaping (String?, Bool) -> Void){
        self.onSearch = callback
    }
    
    @objc private func didTapSearch() {
        executeSearch()
    }
    
    private func executeSearch() {
        textField.resignFirstResponder()
        let keyword = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let isSearching = !(keyword?.isEmpty ?? true)
        onSearch?(keyword, isSearching)
    }
}

extension SearchBarView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        executeSearch()
        return true
    }
}
