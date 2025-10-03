//
//  ImageLoader.swift
//  VNPayChallange
//
//  Created by Le Quang Hung on 1/10/25.
//

import UIKit

final class ImageLoader {
    
    // MARK: - Singleton
    static let shared = ImageLoader()
    
    // MARK: - Properties
    private let session: URLSession
    private let memoryCache = NSCache<NSString, UIImage>()
    private var sharedCache: URLCache
    
    private let defaultRetries = 3

    // MARK: - Init
    /// Default Init
    private init() {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.timeoutIntervalForRequest = 10
        
        let cache = URLCache(memoryCapacity: 20*1024*1024,
                             diskCapacity: 200*1024*1024,
                             diskPath: "ImageCache")
        self.sharedCache = cache
        self.session = URLSession(configuration: config)
        self.memoryCache.countLimit = 50
    }
    
    /// Init for Unit Test
    init(session: URLSession, urlCache: URLCache? = nil) {
        self.session = session
        self.sharedCache = urlCache ?? URLCache(memoryCapacity: 20*1024*1024,
                                                diskCapacity: 200*1024*1024,
                                                diskPath: nil)
        self.memoryCache.countLimit = 50
    }
    
    // MARK: - Public
    
    @discardableResult
    func loadImage(from url: URL,
                   retries: Int = 3,
                   completion: @escaping (Result<UIImage, NetworkError>) -> Void) -> URLSessionDataTask? {
        
        let key = url.absoluteString as NSString
        
        // Check memory cache
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
        
        return attempt(request, key: key, retries: retries, completion: completion)
    }
    
    /// Reset caches (Use for Unit Test)
    func removeObjs() {
        memoryCache.removeAllObjects()
        sharedCache.removeAllCachedResponses()
    }

    func loadMemoryCache(cachedImage: UIImage, key: NSString) {
        memoryCache.setObject(cachedImage, forKey: key)
    }

    func loadSharedCache(cachedResponse: CachedURLResponse, url: URL) {
        sharedCache.storeCachedResponse(cachedResponse, for: URLRequest(url: url))
    }
    
    // MARK: - Private
    
    private func attempt(_ request: URLRequest,
                         key: NSString,
                         retries: Int,
                         completion: @escaping (Result<UIImage, NetworkError>) -> Void) -> URLSessionDataTask {
        
        let task = session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            // Handle error
            if let error = error as NSError? {
                let autoRetryError: [Int] = [NSURLErrorTimedOut, NSURLErrorNetworkConnectionLost, NSURLErrorNotConnectedToInternet]

                if autoRetryError.contains(error.code) && retries > 0 {
                    print("Retries \(retries) left ...")
                    let delay = pow(2.0, Double(self.defaultRetries - retries))
                    DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                        _ = self.attempt(request, key: key, retries: retries - 1, completion: completion)
                    }
                    return
                }
                
                let networkError: NetworkError
                switch error.code {
                    case NSURLErrorNotConnectedToInternet:
                        networkError = .networkNotConnected
                    case NSURLErrorNetworkConnectionLost:
                        networkError = .networkUnAvailable
                    case NSURLErrorTimedOut:
                        networkError = .timeout
                    default:
                        networkError = .unknown(error)
                }
                DispatchQueue.main.async{
                    completion(.failure(networkError))
                }
                return
            }
            
            // Validate response
            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async { completion(.failure(.invalidResponse)) }
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                DispatchQueue.main.async { completion(.failure(.serverError(statusCode: httpResponse.statusCode))) }
                return
            }
            
            // Validate data
            guard let data = data else {
                DispatchQueue.main.async { completion(.failure(.emptyData)) }
                return
            }
            
            guard let image = UIImage(data: data) else {
                DispatchQueue.main.async { completion(.failure(.invalidImageData)) }
                return
            }
            
            // Save to caches
            self.memoryCache.setObject(image, forKey: key)
            let cachedResponse = CachedURLResponse(response: httpResponse, data: data)
            self.sharedCache.storeCachedResponse(cachedResponse, for: request)
            
            DispatchQueue.main.async {
                completion(.success(image))
            }
        }
        
        task.resume()
        return task
    }
}
