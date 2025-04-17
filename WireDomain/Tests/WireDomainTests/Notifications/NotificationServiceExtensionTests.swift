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

import WireAPISupport
import WireDataModel
import WireDataModelSupport
import WireTestingPackage
import XCTest
@testable import WireAPI
@testable import WireDomain
@testable import WireDomainSupport

final class NotificationServiceExtensionTests: XCTestCase {
    private var sut: NotificationServiceExtension!
    
    override func setUp() async throws {
        sut = NotificationServiceExtension()
    }
    
    override func tearDown() async throws {
        sut = nil
    }
    
    func test() async throws {
        
        sut.didReceive(<#T##request: UNNotificationRequest##UNNotificationRequest#>, withContentHandler: <#T##(UNNotificationContent) -> Void#>)
    }
    
}
