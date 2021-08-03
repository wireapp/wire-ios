//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

import XCTest
import UniformTypeIdentifiers
import CoreServices
@testable import WireUtilities

final class UTIHelperTests: XCTestCase {

    func testThatconformsToVectorTypeIdentifiesSVG() {
        // given, when, then
        XCTAssert(UTIHelper.conformsToVectorType(uti: "public.svg-image"))
    }

    func testThatConformsTypeIdentifiesJSONIsNotImageOrVectorType() {
        // given
        let sut = "public.json"

        // when & then
        XCTAssertFalse(UTIHelper.conformsToImageType(uti: sut))
        XCTAssertFalse(UTIHelper.conformsToVectorType(uti: sut))

        XCTAssert(UTIHelper.conformsToJsonType(uti: sut))
    }

    func testThatConformsToImageTypeIdentifiesCommonImageTypes() {
        // given
        let suts = ["public.jpeg",
                    "com.compuserve.gif",
                    "public.png",
                    "public.svg-image"]

        suts.forEach { sut in
            // when & then
            XCTAssert(UTIHelper.conformsToImageType(uti: sut), "\(sut) does not conorms to image type")
        }
    }

    func testThatConvertToUtiConvertsCommonImageTypes() {

        // given & when & then
        XCTAssertEqual(UTIHelper.convertToUti(mime: "image/jpeg"), "public.jpeg")
        XCTAssertEqual(UTIHelper.convertToUti(mime: "image/gif"), "com.compuserve.gif")
        XCTAssertEqual(UTIHelper.convertToUti(mime: "image/png"), "public.png")
        XCTAssertEqual(UTIHelper.convertToUti(mime: "image/svg+xml"), "public.svg-image")
    }

    func testThatConvertToMimeConvertsCommonImageTypes() {
        // given & when & then
        XCTAssertEqual(UTIHelper.convertToMime(uti: "public.jpeg"), "image/jpeg")
        XCTAssertEqual(UTIHelper.convertToMime(uti: "com.compuserve.gif"), "image/gif")
        XCTAssertEqual(UTIHelper.convertToMime(uti: "public.png"), "image/png")
        XCTAssertEqual(UTIHelper.convertToMime(uti: "public.svg-image"), "image/svg+xml")

    }
}
