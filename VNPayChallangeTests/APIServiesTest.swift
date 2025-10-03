 import XCTest
 @testable import VNPayChallange

 final class APIServicesTests: XCTestCase {
     var api: APIServices!
     var session: URLSession!

     override func setUp() {
         super.setUp()
         let config = URLSessionConfiguration.ephemeral
         config.protocolClasses = [MockURLProtocol.self]
         session = URLSession(configuration: config)
         api = APIServices(session: session)
     }

     override func tearDown() {
         api = nil
         session = nil
         MockURLProtocol.requestHandler = nil
         super.tearDown()
     }

     func testFetchPhotos_success() {
         let expectation = self.expectation(description: "Success response")

         let mockJSON = """
         [
             {"id":"1","author":"Alice","width":0,"height":0,"url":"","download_url":""},
             {"id":"2","author":"Bob","width":0,"height":0,"url":"","download_url":""}
         ]
         """.data(using: .utf8)!

         MockURLProtocol.requestHandler = { _ in
             let response = HTTPURLResponse(url: URL(string: "https://picsum.photos/v2/list")!,
                                            statusCode: 200, httpVersion: nil, headerFields: nil)!
             return (response, mockJSON)
         }

         api.fetchPhotos { result, _ in
             switch result {
             case .success(let photos):
                 XCTAssertEqual(photos.count, 2)
                 XCTAssertEqual(photos.first?.author, "Alice")
             case .failure(let error):
                 XCTFail("Expected success, got error \(error)")
             }
             expectation.fulfill()
         }

         wait(for: [expectation], timeout: 2)
     }

     func testFetchPhotos_serverError() {
         let expectation = self.expectation(description: "Server error")

         MockURLProtocol.requestHandler = { _ in
             let response = HTTPURLResponse(url: URL(string: "https://picsum.photos/v2/list")!,
                                            statusCode: 500, httpVersion: nil, headerFields: nil)!
             return (response, nil)
         }

         api.fetchPhotos { result, _ in
             switch result {
             case .success:
                 XCTFail("Expected server error")
             case .failure(let error):
                 if case .serverError(let code) = error {
                     XCTAssertEqual(code, 500)
                 } else {
                     XCTFail("Expected serverError but got \(error)")
                 }
             }
             expectation.fulfill()
         }

         wait(for: [expectation], timeout: 2)
     }

     func testFetchPhotos_timeout() {
         let expectation = self.expectation(description: "Timeout error")

         MockURLProtocol.requestHandler = { _ in
             throw NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut)
         }

         api.fetchPhotos { result, didRetry in
             if case .failure(let error) = result {
                 if case .timeout = error {
                     XCTAssertTrue(didRetry)
                 } else {
                     XCTFail("Expected timeout, got \(error)")
                 }
             } else {
                 XCTFail("Expected failure")
             }
             expectation.fulfill()
         }

         wait(for: [expectation], timeout: 2)
     }

     func testFetchPhotos_networkNotconnected() {
         let expectation = self.expectation(description: "Network not connected")

         MockURLProtocol.requestHandler = { _ in
             throw NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
         }

         api.fetchPhotos { result, didRetry in
             if case .failure(let error) = result {
                 if case .networkNotConnected = error {
                     XCTAssertTrue(didRetry)
                 } else {
                     XCTFail("Expected networkNotConnected, got \(error)")
                 }
             } else {
                 XCTFail("Expected failure")
             }
             expectation.fulfill()
         }

         wait(for: [expectation], timeout: 2)
     }

     func testFetchPhotos_networkUnavailable() {
         let expectation = self.expectation(description: "Network Unavailable")

         MockURLProtocol.requestHandler = { _ in
             throw NSError(domain: NSURLErrorDomain, code: NSURLErrorNetworkConnectionLost)
         }

         api.fetchPhotos { result, didRetry in 
             if case .failure(let error) = result {
                 if case .networkUnAvailable = error {
                     XCTAssertTrue(didRetry)
                 } else {
                     XCTFail("Expected networkUnavailable, got \(error)")
                 } 
             } else {
                 XCTFail("Expected failure")
             }
             expectation.fulfill()
         }

         wait(for: [expectation], timeout: 2)
     }

     func testFetchPhotos_invalidResponse() {
         let expectation = self.expectation(description: "Invalid response")

         MockURLProtocol.requestHandler = { _ in
             let response = URLResponse(url: URL(string: "https://picsum.photos/v2/list")!,
                                        mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
             let data: Data? = nil
             return (response, data)
         }

         api.fetchPhotos { result, _ in
             if case .failure(let error) = result {
                 if case .invalidResponse = error { }
                 else { XCTFail("Expected invalidResponse, got \(error)") }
             } else { XCTFail("Expected failure") }
             expectation.fulfill()
         }

         wait(for: [expectation], timeout: 2)
     }

     func testFetchPhotos_decodingError() {
         let expectation = self.expectation(description: "Decoding error")

         let invalidJSON = "invalid json".data(using: .utf8)!

         MockURLProtocol.requestHandler = { _ in
             let response = HTTPURLResponse(url: URL(string: "https://picsum.photos/v2/list")!,
                                            statusCode: 200, httpVersion: nil, headerFields: nil)!
             return (response, invalidJSON)
         }

         api.fetchPhotos { result, _ in
             if case .failure(let error) = result {
                 if case .decodingFailed = error { }
                 else { XCTFail("Expected decodingFailed, got \(error)") }
             } else { XCTFail("Expected failure") }
             expectation.fulfill()
         }

         wait(for: [expectation], timeout: 2)
     }

     func testFetchPhotos_emptyData() {

     }
 }
