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

import XCTest

@testable import Wire

final class AccountAlreadyLoggedInPolicyTests: XCTestCase {

    private let idpA = UUID()
    private let idpB = UUID()

    // MARK: - Not a multi-ingress login
    //
    // A plain (non-multi-ingress) login into an account already known on
    // this device is always treated as "already logged in", regardless of
    // whether the account currently has an active session.

    func testNotMultiIngress_AccountInactive_IsAlreadyLoggedIn() {
        XCTAssertTrue(AccountAlreadyLoggedInPolicy.isAlreadyLoggedIn(
            isAccountActive: false,
            ssoIdpChangeDetectionEnabled: false,
            multiIngressIdentityProviderID: nil,
            lastSSOIdentityProviderID: nil
        ))
    }

    func testNotMultiIngress_AccountActive_IsAlreadyLoggedIn() {
        XCTAssertTrue(AccountAlreadyLoggedInPolicy.isAlreadyLoggedIn(
            isAccountActive: true,
            ssoIdpChangeDetectionEnabled: false,
            multiIngressIdentityProviderID: nil,
            lastSSOIdentityProviderID: idpA
        ))
    }

    // MARK: - Multi-ingress login, flag disabled (backend fails open)

    func testMultiIngress_FlagDisabled_AccountActive_IsAlreadyLoggedIn() {
        XCTAssertTrue(AccountAlreadyLoggedInPolicy.isAlreadyLoggedIn(
            isAccountActive: true,
            ssoIdpChangeDetectionEnabled: false,
            multiIngressIdentityProviderID: idpB,
            lastSSOIdentityProviderID: idpA
        ))
    }

    func testMultiIngress_FlagDisabled_AccountInactive_IsNotAlreadyLoggedIn() {
        XCTAssertFalse(AccountAlreadyLoggedInPolicy.isAlreadyLoggedIn(
            isAccountActive: false,
            ssoIdpChangeDetectionEnabled: false,
            multiIngressIdentityProviderID: idpB,
            lastSSOIdentityProviderID: idpA
        ))
    }

    // MARK: - Multi-ingress login, flag enabled, same IdP

    func testMultiIngress_FlagEnabled_SameIdP_AccountActive_IsAlreadyLoggedIn() {
        XCTAssertTrue(AccountAlreadyLoggedInPolicy.isAlreadyLoggedIn(
            isAccountActive: true,
            ssoIdpChangeDetectionEnabled: true,
            multiIngressIdentityProviderID: idpA,
            lastSSOIdentityProviderID: idpA
        ))
    }

    func testMultiIngress_FlagEnabled_SameIdP_AccountInactive_IsNotAlreadyLoggedIn() {
        XCTAssertFalse(AccountAlreadyLoggedInPolicy.isAlreadyLoggedIn(
            isAccountActive: false,
            ssoIdpChangeDetectionEnabled: true,
            multiIngressIdentityProviderID: idpA,
            lastSSOIdentityProviderID: idpA
        ))
    }

    // MARK: - Multi-ingress login, flag enabled, IdP changed
    //
    // This is the regression this policy fixes: an IdP change must always
    // be let through to the multi-ingress alert, even for an active account,
    // rather than being blocked with a generic "already logged in" error.

    func testMultiIngress_FlagEnabled_IdPChanged_AccountActive_IsNotAlreadyLoggedIn() {
        XCTAssertFalse(AccountAlreadyLoggedInPolicy.isAlreadyLoggedIn(
            isAccountActive: true,
            ssoIdpChangeDetectionEnabled: true,
            multiIngressIdentityProviderID: idpB,
            lastSSOIdentityProviderID: idpA
        ))
    }

    func testMultiIngress_FlagEnabled_IdPChanged_AccountInactive_IsNotAlreadyLoggedIn() {
        XCTAssertFalse(AccountAlreadyLoggedInPolicy.isAlreadyLoggedIn(
            isAccountActive: false,
            ssoIdpChangeDetectionEnabled: true,
            multiIngressIdentityProviderID: idpB,
            lastSSOIdentityProviderID: idpA
        ))
    }

    func testMultiIngress_FlagEnabled_NoPreviousIdP_AccountActive_IsNotAlreadyLoggedIn() {
        // No IdP has ever been recorded for this account: treat it the same
        // as a change so the multi-ingress flow can record it.
        XCTAssertFalse(AccountAlreadyLoggedInPolicy.isAlreadyLoggedIn(
            isAccountActive: true,
            ssoIdpChangeDetectionEnabled: true,
            multiIngressIdentityProviderID: idpB,
            lastSSOIdentityProviderID: nil
        ))
    }

}
