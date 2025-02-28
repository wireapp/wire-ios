//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

import WireCellsAPI
import XCTest

@testable @preconcurrency import WireCellsImplementation

/// These tests are intended for locally testing the service, not for CI.
final class WireCellsTests: XCTestCase {

    private enum Constants {
        static let endpointURL = URL(string: "https://service.zeta.pydiocells.com")!
        static let rootPath = URL(string: "wire-cells-ios")!
        // Replace `nil` with the secret key, which can be obtained on 1Password ("Wire Cells demo secret key")
        static let secretKey: String! = nil
    }

    var wireCellsService: (any WireCellsService)!

    override func setUp() async throws {
        guard Constants.secretKey != nil else {
            fatalError("Please provide a secret key")
        }
        wireCellsService = try WireCellsServiceImplementation(
            endpointURL: Constants.endpointURL,
            rootPath: Constants.rootPath,
            secretKey: Constants.secretKey
        )
    }

    override func tearDown() {
        wireCellsService = nil
    }

    func testUploadFile() async throws {
        let data = "Hello World!".data(using: .utf8)! // swiftlint:disable:this non_optional_string_data_conversion
        for await result in wireCellsService.uploadFiles([
            WireCellsFileUploadInfo(data: data, uploadPath: "HelloWorld.txt")
        ]) {
            switch result {
            case .started:
                break
            case .uploading:
                break
            case let .success(fileUploadInfo, uploadedNode):
                XCTAssert(uploadedNode.path.absoluteString == "\(Constants.rootPath)/\(fileUploadInfo.uploadPath)")
            case let .failure(_, error):
                XCTFail(error.localizedDescription)
            }
        }
    }

    func testListFilesRoot() async {
        do {
            let results = try await wireCellsService.listFiles()
            XCTAssert(results.count == 3)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testListFilesEmptyFolder() async {
        // XCTest Documentation
        // https://developer.apple.com/documentation/xctest

        // Defining Test Cases and Test Methods
        // https://developer.apple.com/documentation/xctest/defining_test_cases_and_test_methods

        do {
            let results = try await wireCellsService.listFiles(atPath: "EmptyFolderTree/EmptyFolderTreeLeaf")
            XCTAssert(results.isEmpty)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testListFilesEmptyFolderTree() async {
        // XCTest Documentation
        // https://developer.apple.com/documentation/xctest

        // Defining Test Cases and Test Methods
        // https://developer.apple.com/documentation/xctest/defining_test_cases_and_test_methods

        do {
            let results = try await wireCellsService.listFiles(atPath: "EmptyFolderTree")
            XCTAssert(results.count == 1)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}
