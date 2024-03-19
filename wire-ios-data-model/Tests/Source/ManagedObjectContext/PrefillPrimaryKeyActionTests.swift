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

import XCTest
@testable import WireDataModel

final class PrefillPrimaryKeyActionTests: XCTestCase {

    var sut: PrefillPrimaryKeyAction!
    override func setUpWithError() throws {
        sut = PrefillPrimaryKeyAction()
    }

    override func tearDownWithError() throws {
        sut = nil
    }

    func testExample() throws {
        let helper = DatabaseMigrationHelper()

        try helper.migrateStoreToCurrentVersion(sourceVersion: "2.110.0", preMigrationAction: { context in
            if #available(iOS 15.0, *) {
                let request = NSFetchRequest<NSManagedObject>(entityName: ZMConversation.entityName())
                let result = try context.fetch(request)
                var i = 0
                for object in result {
                    let data = object.value(forKey: "remoteIdentifier_data") as! Data
                    let remoteId = UUID(data: data)
                    let domain = object.value(forKey: "domain") as? String
                    print("🕵🏽 conv \(i) in db", remoteId, domain)
                    print("🕵🏽 conv2 in db", ZMConversation.primaryKey(from: remoteId, domain: domain))
                    i += 1
                }

            } else {
                // Fallback on earlier versions
            }

            for i in 1...100 {
                let user = ZMUser.insert(in: context, id: UUID(), name: "user \(i)")
                user.domain = "example.com"
            }
            try context.save()

        }, postMigrationAction: { context in
            let request = NSFetchRequest<NSManagedObject>(entityName: ZMUser.entityName())
            let result = try context.fetch(request)

            for object in result {
                print(object)
            }
        }, for: self)
    }

}
