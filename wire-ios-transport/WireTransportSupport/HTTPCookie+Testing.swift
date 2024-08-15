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

@testable import WireTransport

extension HTTPCookie {

    @objc public class func validCookieData() -> Data {
        validCookieData(string: "zuid=something; Path=/access; Expires=Tue, 06-Oct-2099 11:46:18 GMT; HttpOnly; Secure")
    }

    @objc public class func validCookieData(string: String) -> Data {
        HTTPCookie.extractCookieData(from: string, url: URL(string: "https://example.com")!)!
    }

}
