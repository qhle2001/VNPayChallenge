//
//  Network.swift
//  VNPayChallange
//
//  Created by Le Quang Hung on 2/10/25.
//

import Foundation

enum NetworkError: Error{
    case networkUnAvailable
    case networkNotConnected
    case invalidURL
    case invalidResponse
    case emptyData
    case decodingFailed(Error)
    case invalidImageData
    case serverError(statusCode: Int)
    case timeout
    case unknown(Error)
}

extension NetworkError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .networkUnAvailable:
            return "Network connection unavailable. Please check your Internet access."
        case .networkNotConnected:
            return "No Internet connection. Please check your Wi-Fi or mobile data."
        case .invalidURL:
            return "The URL provided is invalid."
        case .invalidResponse:
            return "The server response was invalid."
        case .emptyData:
            return "No data was returned by the server."
        case .decodingFailed(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .invalidImageData:
            return "The data could not be converted to an image."
        case .serverError(let statusCode):
            return "Server returned an error with status code: \(statusCode)."
        case .timeout:
            return "The request timed out."
        case .unknown(let error):
            return "An unknown error occurred: \(error.localizedDescription)"
        }
    }
}

enum InternetStatus{
    case noConnection
    case unavailable
    case connected
    case other
}
