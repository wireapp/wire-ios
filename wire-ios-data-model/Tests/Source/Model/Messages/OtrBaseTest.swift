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

import Foundation
import XCTest

class OtrBaseTest: XCTestCase {
    static var sharedContainerURL: URL {
        try! FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
    }

    static var legacyOtrDirectory: URL {
        FileManager.keyStoreURL(accountDirectory: sharedContainerURL, createParentIfNeeded: true)
    }

    static func otrDirectoryURL(accountIdentifier: UUID) -> URL {
        let accountDirectory = CoreDataStack.accountDataFolder(
            accountIdentifier: accountIdentifier,
            applicationContainer: sharedContainerURL
        )
        return FileManager.keyStoreURL(accountDirectory: accountDirectory, createParentIfNeeded: true)
    }

    static func legacyAccountOtrDirectory(accountIdentifier: UUID) -> URL {
        FileManager.keyStoreURL(
            accountDirectory: sharedContainerURL.appendingPathComponent(accountIdentifier.uuidString),
            createParentIfNeeded: true
        )
    }

    override func setUp() {
        super.setUp()

        // clean stored cryptobox files
        if let items = (try? FileManager.default.contentsOfDirectory(
            at: OtrBaseTest.sharedContainerURL,
            includingPropertiesForKeys: nil,
            options: []
        )) {
            items.forEach { try? FileManager.default.removeItem(at: $0) }
        }
    }
}
