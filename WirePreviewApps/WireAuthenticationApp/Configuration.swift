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

import Foundation
import WireAPI
import WireAPISupport
import WireReusableUIComponents

struct Configuration {

    let defaultBackendEnvironment: BackendEnvironment
    let minTLSVersion: TLSVersion
    let defaultAPIVersion: APIVersion
    let accountsURL: URL
    let passwordValidator: any PasswordValidator

    static let live = Configuration(
        defaultBackendEnvironment: .anta,
        minTLSVersion: .v1_3,
        defaultAPIVersion: .v8,
        accountsURL: .antaAccountsURL,
        passwordValidator: LoginPasswordValidator()
    )

}

private struct LoginPasswordValidator: PasswordValidator {

    func validate(_ password: String) -> Bool {
        !password.isEmpty
    }

    var localizedRulesDescription: String? {
        "Password rules"
    }

}

private extension BackendEnvironment {

    static let anta = BackendEnvironment(
        url: URL(string: "https://nginz-https.anta.wire.link")!,
        webSocketURL: URL(string: "https://nginz-ssl.anta.wire.link")!,
        pinnedKeys: [],
        proxySettings: nil
    )

}

private extension URL {

    static let antaAccountsURL = URL(string: "https://account.anta.wire.link")!

}
