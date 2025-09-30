//
//  PhotoCell.swift
//  VNPayChallange
//
//  Created by Le Quang Hung on 1/10/25.
//

import UIKit

final class PhotoCell: UITableViewCell {

    private let photoImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let authorLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .darkGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupConstraints()
    }

    private func setupUI() {
        contentView.addSubview(photoImageView)
        contentView.addSubview(authorLabel)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            photoImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            photoImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            photoImageView.widthAnchor.constraint(equalToConstant: 80),
            photoImageView.heightAnchor.constraint(equalToConstant: 80),
            photoImageView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -8),

            authorLabel.centerYAnchor.constraint(equalTo: photoImageView.centerYAnchor),
            authorLabel.leadingAnchor.constraint(equalTo: photoImageView.trailingAnchor, constant: 12),
            authorLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }

    func configure(with photo: Photo) {
        authorLabel.text = photo.author
        // giả sử Photo có url string
        if let url = URL(string: photo.download_url) {
            // load ảnh async (tạm thời, ví dụ nhanh)
            DispatchQueue.global().async {
                if let data = try? Data(contentsOf: url) {
                    DispatchQueue.main.async {
                        self.photoImageView.image = UIImage(data: data)
                    }
                }
            }
        }
    }
}

