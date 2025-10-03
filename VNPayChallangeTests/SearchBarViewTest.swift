//
//  SearchBarViewTest.swift
//  VNPayChallange
//
//  Created by Le Quang Hung on 3/10/25.
//

import XCTest
@testable import VNPayChallange

final class SearchBarViewTests: XCTestCase {

    var searchBar: SearchBarView!

    override func setUp() {
        super.setUp()
        searchBar = SearchBarView(frame: .zero)
    }

    override func tearDown() {
        searchBar = nil
        super.tearDown()
    }

    func testSearchCallbackWithText() {
        let expectation = self.expectation(description: "Search callback called with text")

        searchBar.textField.text = "Alice"
        searchBar.onSearchAction { keyword, isSearching in
            XCTAssertEqual(keyword, "Alice")
            XCTAssertTrue(isSearching)
            expectation.fulfill()
        }

        searchBar.searchButton.sendActions(for: .touchUpInside)

        wait(for: [expectation], timeout: 1)
    }

    func testSearchCallbackWithEmptyText() {
        let expectation = self.expectation(description: "Search callback called with empty text")

        searchBar.textField.text = "   "
        searchBar.onSearchAction { keyword, isSearching in
            XCTAssertEqual(keyword, "")
            XCTAssertFalse(isSearching)
            expectation.fulfill()
        }

        searchBar.searchButton.sendActions(for: .touchUpInside)

        wait(for: [expectation], timeout: 1)
    }

    func testSearchCallbackOnReturnKey() {
        let expectation = self.expectation(description: "Search callback called when pressing Return key")

        searchBar.textField.text = "Jey"
        searchBar.onSearchAction { keyword, isSearching in
            XCTAssertEqual(keyword, "Jey")
            XCTAssertTrue(isSearching)
            expectation.fulfill()
        }

        _ = searchBar.textField.delegate?.textFieldShouldReturn?(searchBar.textField)

        wait(for: [expectation], timeout: 1)
    }
    
    func testSearchCallbackTrimsWhitespace() {
        let expectation = self.expectation(description: "Search callback trims whitespace")

        searchBar.textField.text = "  Charlie  "
        searchBar.onSearchAction { keyword, isSearching in
            XCTAssertEqual(keyword, "Charlie")
            XCTAssertTrue(isSearching)
            expectation.fulfill()
        }

        searchBar.searchButton.sendActions(for: .touchUpInside)

        wait(for: [expectation], timeout: 1)
    }
}
