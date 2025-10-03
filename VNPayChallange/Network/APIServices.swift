//
//  APIClient.swift
//  VNPayChallange
//
//  Created by Le Quang Hung on 30/9/25.
//

import Foundation

final class APIServices {

    func fetchPhotos(
        page: Int = 1, 
        limit: Int = 100, 
        retries: Int = 3, 
        timeout: TimeInterval = 10,
        completion: @escaping (Result<[Photo], NetworkError>, Bool) -> Void
    ) {
        let urlString = "https://picsum.photos/v2/list?page=\(page)&limit=\(limit)"
        guard let url = URL(string: urlString) else {
            completion(.failure(.invalidURL), false)
            return
        }

        print("APIServices: fetching \(url.absoluteString)")

        var request = URLRequest(url: url)
        request.timeoutInterval = timeout
        attemptRequest(request, retries: retries, completion: completion)
    }
    private func attemptRequest(
        _ request: URLRequest, 
        retries: Int,
        isRetry: Bool = false,
        completion: @escaping (Result<[Photo], NetworkError>, Bool) -> Void
    ){
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error as NSError? {
                if error.domain == NSURLErrorDomain {
                    let autoRetryError: [Int] = [NSURLErrorTimedOut, NSURLErrorNetworkConnectionLost, NSURLErrorNotConnectedToInternet]

                    if autoRetryError.contains(error.code) && retries > 0{
                        let isConnectionError = (error.code == NSURLErrorTimedOut || error.code == NSURLErrorNetworkConnectionLost || error.code == NSURLErrorNotConnectedToInternet)
                        print("Network timeout, retrying (\(retries - 1) left)...")
                        self.attemptRequest(request, retries: retries - 1, isRetry: true, completion: completion)
                        return
                    }

                    let networkError: NetworkError
                    let didRetry: Bool
                    switch error.code {
                        case NSURLErrorNotConnectedToInternet:
                            networkError = .networkNotConnected
                            didRetry = true
                        case NSURLErrorNetworkConnectionLost:
                            networkError = .networkUnAvailable
                            didRetry = true
                        case NSURLErrorTimedOut:
                            networkError = .timeout
                            didRetry = true
                        default:
                            networkError = .unknown(error)
                            didRetry = false
                    }
                    completion(.failure(networkError), didRetry)
                    return
                }
                
                completion(.failure(.unknown(error)), isRetry)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.invalidResponse), isRetry)
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(.serverError(statusCode: httpResponse.statusCode)), isRetry)
                return
            }

            guard let data = data else {
                completion(.failure(.emptyData), isRetry)
                return
            }

            do {
                let photos = try JSONDecoder().decode([Photo].self, from: data)
                completion(.success(photos), isRetry)
            } catch {
                print("APIServices decode error:", error)
                completion(.failure(.decodingFailed(error)), isRetry)
            }
        }.resume()
    }
}
