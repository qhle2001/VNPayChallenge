//
//  PhotoListViewModel.swift
//  VNPayChallange
//
//  Created by Le Quang Hung on 1/10/25.
//

import Foundation

final class PhotoListViewModel {
    private let apiService = APIServices()
    var photos: [Photo] = []

    var didUpdatePhotos: (() -> Void)?
    var didFailWithError: ((Error, Bool) -> Void)?

    func loadPhotos(_ page: Int = 1) {
        print("PhotoListViewModel.loadPhotos called")
        apiService.fetchPhotos(page: page) { [weak self] result, didRetry in
            DispatchQueue.main.async {
                switch result {
                case .success(let photos):
                    print("PhotoListViewModel: fetched \(photos.count) photos")
                    self?.photos = photos
                    self?.didUpdatePhotos?()
                case .failure(let error):
                    print("PhotoListViewModel error: \(error.localizedDescription)")
                    self?.didFailWithError?(error, didRetry)
                }
            }
        }
    }
}
