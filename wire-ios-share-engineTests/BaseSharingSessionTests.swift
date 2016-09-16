//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
import ZMCDataModel
@testable import WireShareEngine

class FakeAuthenticationStatus: AuthenticationStatusProvider {
    var state: AuthenticationState = .authenticated
}

class BaseSharingSessionTests: XCTestCase {

    var moc: NSManagedObjectContext!
    var sharingSession: SharingSession!
    var authenticationStatus: FakeAuthenticationStatus!

    override func setUp() {
        super.setUp()
        
        let fm = FileManager.default
        let url = try! fm.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create:true)
        
        authenticationStatus = FakeAuthenticationStatus()
        sharingSession = try! SharingSession(databaseDirectory: url, authenticationStatusProvider: authenticationStatus)
        moc = sharingSession.managedObjectContext
    }

}
