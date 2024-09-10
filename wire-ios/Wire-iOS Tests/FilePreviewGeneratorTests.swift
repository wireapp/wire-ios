//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

import MobileCoreServices
import UniformTypeIdentifiers
import XCTest

@testable import Wire
@testable import WireCommonComponents

final class FilePreviewGeneratorTests: XCTestCase {

    private lazy var bundle = Bundle(for: Self.self)

    func testThatItDoesNotBreakOn0x0PDF() throws {

        // Given
        let pdfURL = try XCTUnwrap(bundle.url(forResource: "0x0", withExtension: "pdf"))
        let sut = PDFFilePreviewGenerator(callbackQueue: .main, thumbnailSize: CGSize(width: 100, height: 100))

        // When
        let expectation = expectation(description: "Finished generating the preview")
        sut.generatePreview(pdfURL, type: .pdf) { image in
            XCTAssertNil(image)
            expectation.fulfill()
        }

        // Then
        waitForExpectations(timeout: 2)
    }

    func testThatItDoesNotBreakOnHugePDF() throws {

        // Given
        let pdfURL = try XCTUnwrap(bundle.url(forResource: "huge", withExtension: "pdf"))
        let sut = PDFFilePreviewGenerator(callbackQueue: .main, thumbnailSize: CGSize(width: 100, height: 100))

        // When
        let expectation = expectation(description: "Finished generating the preview")
        sut.generatePreview(pdfURL, type: .pdf) { image in
            XCTAssertNil(image)
            expectation.fulfill()
        }

        // Then
        waitForExpectations(timeout: 2)
    }
}
