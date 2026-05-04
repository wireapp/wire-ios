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

import Combine
import SwiftUI
import WireAuthentication
import WireAuthenticationUI
import WireFoundation
import WireMultiBackendUI
import WireNetwork
import WireReusableUIComponents

struct ContentView: View {

    let configuration: Configuration

    var body: some View {
        WireAuthenticationAssembly()
            .assemble(
                authenticationType: .new,
                environmentType: configuration.defaultBackendEnvironment,
                environment: BackendEnvironment2(
                    title: "Mock backend",
                    endpoints: Endpoints(
                        backendURL: URL(string: "https://prod-nginz-https.wire.com")!,
                        backendWSURL: URL(string: "https://prod-nginz-ssl.wire.com")!,
                        blackListURL: URL(string: "https://clientblacklist.wire.com/prod")!,
                        teamsURL: URL(string: "https://teams.wire.com")!,
                        accountsURL: URL(string: "https://account.wire.com")!,
                        websiteURL: URL(string: "https://wire.com")!,
                        countlyURL: URL(string: "https://wire.count.ly")!,
                    ),
                    proxySettings: nil,
                    pinnedKeys: nil
                ),
                minTLSVersion: configuration.minTLSVersion,
                preferredAPIVersion: .v8,
                accountsURL: configuration.accountsURL,
                howToChangeEmailURL: URL(string: "www.example.com")!,
                howToDeleteAccountURL: URL(string: "www.example.com")!,
                privacyPolicyURL: URL(string: "www.example.com")!,
                termsOfUseURL: URL(string: "www.example.com")!,
                passwordValidator: configuration.passwordValidator,
                ssoCallbackURLScheme: "some scheme",
                appStoreURL: URL(string: "www.example.com")!,
                accountsPublisher: CurrentValuePublisher<[AccountUIModel]>(
                    subject: CurrentValueSubject<[AccountUIModel], Never>(
                        [
                            AccountUIModel(
                                avatarSource: .text("FF"),
                                name: "Name",
                                handle: "@handle",
                                teamName: "Team",
                                backendName: "Backedn",
                                action: {}
                            ),
                            AccountUIModel(
                                avatarSource: .text("DS"),
                                name: "Name 2",
                                handle: "@handle 2",
                                teamName: "Team two",
                                backendName: "Backend two",
                                action: {}
                            )
                        ]
                    )
                ),
                registrationAnalyticsTracker: MockPersonalAccountCreationAnalyticsTracker()
            ).view
    }

}

#Preview {
    ContentView(configuration: .live)
}
