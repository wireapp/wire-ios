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
import ZMCMockTransport
import ZMTesting
@testable import WireShareEngine

class FakeAuthenticationStatus: AuthenticationStatusProvider {
    var state: AuthenticationState = .authenticated
}

class BaseSharingSessionTests: ZMTBaseTest {

    var moc: NSManagedObjectContext!
    var sharingSession: SharingSession!
    var authenticationStatus: FakeAuthenticationStatus!

    override func setUp() {
        super.setUp()

        authenticationStatus = FakeAuthenticationStatus()
        
        let testSession = ZMTestSession(dispatchGroup: dispatchGroup)
        testSession?.shouldUseInMemoryStore = true
        testSession?.prepare(forTestNamed: name)
        
        let url = try! FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let userInterfaceContext = testSession?.uiMOC
        let syncContext = testSession?.syncMOC
        
        let mockTransport = MockTransportSession(dispatchGroup: ZMSDispatchGroup(label: "ZMSharingSession"))
        let transportSession = mockTransport.mockedTransportSession()
        
        let requestGeneratorStore = RequestGeneratorStore(strategies: [])
        let registrationStatus = ClientRegistrationStatus(context: syncContext!)
        let operationLoop = RequestGeneratingOperationLoop(
            userContext: userInterfaceContext!,
            syncContext: syncContext!,
            callBackQueue: .main,
            requestGeneratorStore: requestGeneratorStore,
            transportSession: transportSession
        )

        sharingSession = try! SharingSession(
            userInterfaceContext: userInterfaceContext!,
            syncContext: syncContext!,
            transportSession: transportSession,
            sharedContainerURL: url,
            authenticationStatus: authenticationStatus,
            clientRegistrationStatus: registrationStatus,
            operationLoop: operationLoop
        )

        moc = sharingSession.userInterfaceContext
    }

}
