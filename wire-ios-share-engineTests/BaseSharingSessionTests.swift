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

        authenticationStatus = FakeAuthenticationStatus()
        
        let url                  = try! FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let userInterfaceContext = NSManagedObjectContext.createUserInterfaceContextWithStore(at: url)!
        let syncContext          = NSManagedObjectContext.createSyncContextWithStore(at: url, keyStore: url)!
        let transport            = ZMTransportSession(baseURL: url, websocketURL: url, mainGroupQueue: userInterfaceContext, initialAccessToken: ZMAccessToken(), application: nil, sharedContainerIdentifier: "some identifier")
        
        sharingSession = try! SharingSession(userInterfaceContext: userInterfaceContext, syncContext: syncContext, transportSession: transport, sharedContainerURL: url)
        moc = sharingSession.userInterfaceContext
    }

}
