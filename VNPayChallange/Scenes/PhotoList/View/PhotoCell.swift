//
//  PhotoCell.swift
//  VNPayChallange
//
//  Created by Le Quang Hung on 1/10/25.
//

import UIKit

final class PhotoCell: UITableViewCell {
    
    private var aspectConstraint: NSLayoutConstraint?
    private var currentURL: URL?
    
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
    
    private let sizeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .darkGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let infoStack: UIStackView = {
        let info = UIStackView()
        info.axis = .vertical
        info.spacing = 4
        info.translatesAutoresizingMaskIntoConstraints = false
        return info
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    private let errorLabel: UILabel = {
        let label = UILabel()
        label.text = "Opps!"
        label.isHidden = true
        label.textColor = .black
        label.font = .boldSystemFont(ofSize: 16)
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
        contentView.addSubview(infoStack)
        photoImageView.addSubview(activityIndicator)
        photoImageView.addSubview(errorLabel)
        
        infoStack.addArrangedSubview(authorLabel)
        infoStack.addArrangedSubview(sizeLabel)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            photoImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            photoImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            photoImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
//            photoImageView.heightAnchor.constraint(equalTo: photoImageView.widthAnchor, multiplier: 9.0/16.0),

            infoStack.topAnchor.constraint(equalTo: photoImageView.bottomAnchor, constant: 8),
            infoStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            infoStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            infoStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            
            activityIndicator.centerXAnchor.constraint(equalTo: photoImageView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: photoImageView.centerYAnchor),

            errorLabel.centerXAnchor.constraint(equalTo: photoImageView.centerXAnchor),
            errorLabel.centerYAnchor.constraint(equalTo: photoImageView.centerYAnchor),
            errorLabel.widthAnchor.constraint(equalTo: photoImageView.widthAnchor),
            errorLabel.heightAnchor.constraint(equalTo: photoImageView.heightAnchor)
        ])
    }
    
    func configure(with photo: Photo) {
        guard let url = URL(string: photo.download_url) else { return }
        authorLabel.text = photo.author
        sizeLabel.text = "Size: \(photo.width) x \(photo.height)"

        currentURL = url
        
        photoImageView.image = nil
        errorLabel.isHidden = true
        
        activityIndicator.startAnimating()
        
        if let oldConstraint = aspectConstraint {
            photoImageView.removeConstraint(oldConstraint)
        }
        let aspectRatio = CGFloat(photo.height) / CGFloat(photo.width)
        let newConstraint = photoImageView.heightAnchor.constraint(equalTo: photoImageView.widthAnchor, multiplier: aspectRatio)
        newConstraint.isActive = true
        aspectConstraint = newConstraint
        
        ImageLoader.shared.loadImage(from: url) { [weak self] result in
            guard let self = self else { return }

            if self.currentURL != url { return }
            
            switch result {
            case .success(let image):
                self.photoImageView.image = image
                self.activityIndicator.stopAnimating()
            case .failure(let error):
                self.activityIndicator.stopAnimating()
                self.errorLabel.isHidden = false
                print("Image load error:", error.localizedDescription)
            }
        }
        
    }


}

