import XCTest
import UIKit
@testable import VNPayChallange

final class ImageLoaderTest: XCTestCase {
    private var session: URLSession!
    private var loader: ImageLoader!
    private let testURL: String = "https://example.com/image/png"

    override func setUp() {
        super.setUp()
        
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        self.session = URLSession(configuration: config)


        self.loader = ImageLoader(session: session)
        
        // Reset caches
        loader.removeObjs()
    }

    override func tearDown() {
        session = nil
        loader = nil
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    func testLoadImageMemoryCache() {
        let key = self.testURL as NSString
        let cachedImage = UIImage(systemName: "house")!
        loader.loadMemoryCache(cachedImage: cachedImage, key: key)

        let expectation = self.expectation(description: "Image loaded from memory cache")
        loader.loadImage(from: URL(string: key as String)!) { result in
            switch result {
            case .success(let image):
                XCTAssertEqual(image.pngData(), cachedImage.pngData())
                expectation.fulfill()
            case .failure:
                XCTFail("Expected success from memory cache")
            }
        }
        waitForExpectations(timeout: 1)
    }

    func testLoadImageDiskCache() {
        let url = URL(string: self.testURL)!
        let cachedImage = createTestImage(size: CGSize(width: 24, height: 24))
        let data = cachedImage.pngData()!
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let cachedResponse = CachedURLResponse(response: response, data: data)
        
        loader.loadSharedCache(cachedResponse: cachedResponse, url: url)
        
        let expectation = self.expectation(description: "Image loaded from disk cache")
        
        loader.loadImage(from: url) { result in
            switch result {
            case .success(let image):
                XCTAssertNotNil(image)
                XCTAssertEqual(image.size, cachedImage.size)
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Expected success from disk cache, got \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 1)
    }

    func testLoadImage_Success() {
        let expectation = self.expectation(description: "Image loaded successfully.")

        let image = UIImage(systemName: "house")!
        let data = image.pngData()!

        MockURLProtocol.requestHandler = { _ in
            let response = HTTPURLResponse(
                url: URL(string: self.testURL)!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, data)
        }

        let url = URL(string: self.testURL)!
        loader.loadImage(from: url) { result in
            switch result {
            case .success(let loadedImage):
                XCTAssertNotNil(loadedImage)
            case .failure(let error):
                XCTFail("Expected success but got failure: \(error)")
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2)
    }

    func testLoadImage_Timeout() {
//        let expectation = self.expectation(description: "Timeout with retry")
//        
//        var attemptCount = 0
//
//        MockURLProtocol.requestHandler = { _ in
//            attemptCount += 1
//            throw NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut)
//        }
//
//        let url = URL(string: self.testURL)!
//        loader.loadImage(from: url) { result in
//            if case .failure(let error) = result {
//                if case .timeout = error {
//                    XCTAssertEqual(attemptCount, 4)
//                    expectation.fulfill()
//                } else {
//                    XCTFail("Expected timeout, got \(error)")
//                }
//            } else {
//                XCTFail("Expected failure")
//            }
//        }
//        
//        // Total delay: 2^0 + 2^1 + 2^2 = 1 + 2 + 4 = 7 second
//        wait(for: [expectation], timeout: 10)
    }

    func testLoadImage_serverError() {
//        let expectation = self.expectation(description: "Server error")
//
//        MockURLProtocol.requestHandler = { _ in
//            let response = HTTPURLResponse(url: URL(string: self.testURL)!,
//                                           statusCode: 500,
//                                           httpVersion: nil,
//                                           headerFields: nil)!
//            return (response, nil)
//        }
//
//        loader.loadImage(from: URL(string: self.testURL)!) { result in
//            if case .failure(let error) = result {
//                if case .serverError(let code) = error {
//                    XCTAssertEqual(code, 500)
//                    expectation.fulfill()
//                } else {
//                    XCTFail("Expected serverError, got \(error)")
//                }
//            } else {
//                XCTFail("Expected failure")
//            }
//        }
//
//        wait(for: [expectation], timeout: 2)
    }

    func testLoadImage_networkNotconnected(){
//        let expectation = self.expectation(description: "Network not connected")
//        
//        MockURLProtocol.requestHandler = { _ in
//            throw NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
//        }
//        
//        loader.loadImage(from: URL(string: self.testURL)!) { result in
//            if case .failure(let error) = result {
//                if case .networkNotConnected = error {
//                    expectation.fulfill()
//                } else {
//                    XCTFail("Expected networkNotConnected, got \(error)")
//                }
//            } else {
//                XCTFail("Expected failure")
//            }
//        }
//
//        wait(for: [expectation], timeout: 10)
    }

    func testLoadImage_networkUnavailable() {
        let expectation = self.expectation(description: "Network Unavailable")
        
        MockURLProtocol.requestHandler = { _ in
            throw NSError(domain: NSURLErrorDomain, code: NSURLErrorNetworkConnectionLost)
        }
        
        loader.loadImage(from: URL(string: self.testURL)!){ result in
            if case .failure(let error) = result {
                if case .networkUnAvailable = error {
                    expectation.fulfill()
                } else {
                    XCTFail("Expected networkUnavailable, got \(error)")
                }
            } else {
                XCTFail("Extedted failure")
            }
        }
        wait(for: [expectation], timeout: 10)
    }

    func testLoadImage_invalidResponse() {
        let expectation = self.expectation(description: "Invalid response")
        MockURLProtocol.requestHandler = { _ in
            let response = URLResponse(url: URL(string:self.testURL)!,
                                       mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
            return (response, Data())
        }

        loader.loadImage(from: URL(string: self.testURL)!) { result in
            if case .failure(let error) = result {
                if case .invalidResponse = error {
                    expectation.fulfill()
                } else {
                    XCTFail("Expected invalidResponse, got \(error)")
                }
            } else {
                XCTFail("Expected failure")
            }
        }
        waitForExpectations(timeout: 2)
    }

    func testLoadImage_emptyData() {
    }


    func testLoadImage_invalidImageData() {
        let expectation = self.expectation(description: "Invalid image data")
        MockURLProtocol.requestHandler = { _ in
            let response = HTTPURLResponse(url: URL(string: self.testURL)!,
                                           statusCode: 200, httpVersion: nil, headerFields: nil)!
            let data = "invalid".data(using: .utf8)!
            return (response, data)
        }

        loader.loadImage(from: URL(string: self.testURL)!) { result in
            if case .failure(let error) = result {
                if case .invalidImageData = error {
                    expectation.fulfill()
                } else {
                    XCTFail("Expected invalidImageData, got \(error)")
                }
            } else {
                XCTFail("Expected failure")
            }
        }

        waitForExpectations(timeout: 2)
    }
    
    func createTestImage(size: CGSize = CGSize(width: 24, height: 24), color: UIColor = .red) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 1)
        color.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }

}
