//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

import WireCommonComponents
import XCTest
@testable import Wire

final class URLsTests: XCTestCase {

    func testMeetingGuestLinkHelpWorksWithOlderURLConfigurations() throws {
        let fileURL = try XCTUnwrap(Bundle.fileURL(for: "url", with: "json"))
        let data = try Data(contentsOf: fileURL)
        var configuration = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        configuration.removeValue(forKey: "meetingGuestLinksInfo")

        let urls = try JSONDecoder().decode(
            WireURLs.self,
            from: JSONSerialization.data(withJSONObject: configuration)
        )

        XCTAssertEqual(
            urls.meetingGuestLinksInfoURL.absoluteString,
            "https://support.wire.com/hc/en-us/articles/18464888721053-How-can-I-join-a-meeting-via-a-guest-link"
        )
        XCTAssertNotEqual(urls.meetingGuestLinksInfoURL, urls.guestLinksInfo)
    }

    func testURLConfigurationDecodes() throws {
        // Given
        guard let fileURL = Bundle.fileURL(for: "url", with: "json") else {
            XCTFail("Failed to load url.json file")
            return
        }

        // When / Then
        XCTAssertNoThrow(try fileURL.decode(WireURLs.self))
    }

    func testURLConfigurationDecodesWithoutOptionalHelpLinks() throws {
        let fileURL = try XCTUnwrap(Bundle.fileURL(for: "url", with: "json"))
        let data = try Data(contentsOf: fileURL)
        var configuration = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        configuration.removeValue(forKey: WireURLs.CodingKeys.learnMoreAboutDrivePermissions.rawValue)
        configuration.removeValue(forKey: WireURLs.CodingKeys.learnMoreAboutAdminlessGroupPrevention.rawValue)

        let urls = try JSONDecoder().decode(WireURLs.self, from: JSONSerialization.data(withJSONObject: configuration))

        XCTAssertNil(urls.learnMoreAboutDrivePermissions)
        XCTAssertNil(urls.learnMoreAboutAdminlessGroupPrevention)
    }

}
