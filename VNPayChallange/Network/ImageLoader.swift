//
//  ImageLoader.swift
//  VNPayChallange
//
//  Created by Le Quang Hung on 1/10/25.
//

import UIKit

final class ImageLoader {
    static let shared = ImageLoader()
    private let memoryCache = NSCache<NSString, UIImage>()
    private let sharedCache: URLCache = {
        let memoryCapacity = 20 * 1024 * 1024
        let diskCapacity = 200 * 1024 * 1024
        return URLCache(memoryCapacity: memoryCapacity,
                        diskCapacity: diskCapacity,
                        diskPath: "ImageCache")
    }()
    
    //Config URLSession with timeout
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.timeoutIntervalForRequest = 10
        config.urlCache = sharedCache
        return URLSession(configuration: config)
    }()

    private init() {
        memoryCache.countLimit = 50
    }
    
    @discardableResult
    func loadImage(from url: URL,
                    retries: Int = 3,
                   completion: @escaping (Result<UIImage, NetworkError>) -> Void) -> URLSessionDataTask? {
        let key = url.absoluteString as NSString
        
        if let cachedImage = memoryCache.object(forKey: key) {
            DispatchQueue.main.async {
                completion(.success(cachedImage))
            }
            return nil
        }
        
        // Check disk cache
        let request = URLRequest(url: url)
        if let cachedResponse = sharedCache.cachedResponse(for: request),
           let image = UIImage(data: cachedResponse.data) {
            memoryCache.setObject(image, forKey: key)
            DispatchQueue.main.async {
                completion(.success(image))
            }
            return nil
        }
        
        return attempt(request,
                        key: key,
                        retries: retries,
                        completion: completion)
    }

    // MARK: - private
    private func attempt(_ request: URLRequest,
                        key: NSString,
                        retries: Int,
                        completion: @escaping (Result<UIImage, NetworkError>) -> Void
    ) -> URLSessionDataTask {
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            
            if let error = error as NSError? {

                if retries > 0,
                    [NSURLErrorTimedOut,
                    NSURLErrorNetworkConnectionLost,
                    NSURLErrorNotConnectedToInternet].contains(error.code) {

                    let delay = pow(2.0, Double((3 - retries)))
                    
                    DispatchQueue.global().asyncAfter(deadline: .now() + delay){
                        _ = self.attempt(
                            request,
                            key: key,
                            retries: retries - 1,
                            completion: completion
                        )
                    }

                    return
                }

                DispatchQueue.main.async {
                    if error.domain == NSURLErrorDomain, error.code == NSURLErrorTimedOut {
                        completion(.failure(.timeout))
                    } else if error.code == NSURLErrorCancelled {
                        return
                    } else {
                        completion(.failure(.unknown(error)))
                    }
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    completion(.failure(.invalidResponse))
                }
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                DispatchQueue.main.async {
                    completion(.failure(.serverError(statusCode: httpResponse.statusCode)))
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(.emptyData))
                }
                return
            }
            
            guard let image = UIImage(data: data) else {
                DispatchQueue.main.async {
                    completion(.failure(.invalidImageData))
                }
                return
            }
            
            // Save to caches
            self.memoryCache.setObject(image, forKey: key)
            if let response = response {
                let cachedResponse = CachedURLResponse(response: response, data: data)
                self.sharedCache.storeCachedResponse(cachedResponse, for: request)
            }
            
            DispatchQueue.main.async {
                completion(.success(image))
            }
        }
        
        task.resume()
        return task
    }
}
