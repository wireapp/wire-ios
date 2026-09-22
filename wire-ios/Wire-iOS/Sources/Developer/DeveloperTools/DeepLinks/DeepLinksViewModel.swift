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

import Foundation
import WireSyncEngine

final class DeepLinksViewModel: ObservableObject {

    enum Error: LocalizedError {

        case invalidLink
        case loginUnavailable

        var errorDescription: String? {
            switch self {
            case .invalidLink:
                "The deeplink you have entered is invalid."
            case .loginUnavailable:
                "Could not start login from this screen."
            }
        }

    }

    enum Backend: String, CaseIterable {

        case staging
        case anta
        case bella
        case chala
        case diya
        case elna
        case foma
        case lich
        case fulu
        case imai

    }

    let router: AppRootRouter?
    let onDismiss: (_ completion: @escaping () -> Void) -> Void

    @Published var isShowingAlert = false

    @Published var error: Error?

    // MARK: - Life cycle

    init(
        router: AppRootRouter? = nil,
        onDismiss: @escaping (_ completion: @escaping () -> Void) -> Void = { $0() }
    ) {
        self.router = router
        self.onDismiss = onDismiss
    }

    // MARK: - Actions

    func openLink(urlString: String) {
        if let credentials = DeveloperCredentialsQRCode(scannedCode: urlString) {
            openCredentialQRCode(credentials)
            return
        }

        guard
            let url = URL(string: urlString.trim()),
            (try? URLAction(url: url)) != nil
        else {
            error = .invalidLink
            isShowingAlert = true
            return
        }

        onDismiss {
            _ = self.router?.openDeepLinkURL(url)
        }
    }

    func openSwitchBackendLink(for backend: Backend) {
        let config = switch backend {
        case .staging:
            "https://staging-nginz-https.zinfra.io/deeplink.json"
        default:
            "https://nginz-https.\(backend.rawValue).wire.link/deeplink.json"
        }

        openLink(urlString: "wire://access/?config=\(config)")
    }

    private func openCredentialQRCode(_ credentials: DeveloperCredentialsQRCode) {
        guard let router else {
            error = .loginUnavailable
            isShowingAlert = true
            return
        }

        onDismiss {
            Task { @MainActor in
                guard router.loginWithDeveloperCredentials(
                    email: credentials.email,
                    username: credentials.username,
                    password: credentials.password,
                    backendConfigURL: credentials.backendConfigURL
                ) == true else {
                    return
                }
            }
        }
    }

}

private struct DeveloperCredentialsQRCode {

    let email: String
    let username: String?
    let password: String
    let backendConfigURL: URL

    init?(scannedCode: String) {
        let fields = scannedCode
            .components(separatedBy: .newlines)
            .reduce(into: [String: String]()) { fields, line in
                let parts = line.split(separator: ":", maxSplits: 1)
                guard parts.count == 2 else { return }

                let key = parts[0]
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased()
                let value = parts[1]
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                fields[key] = value
            }

        let email = fields["email"] ?? fields["owner email"] ?? fields["member email"]
        let username = fields["username"] ?? fields["owner username"] ?? fields["member username"]
        let password = fields["password"] ?? fields["owner password"] ?? fields["member password"]
        let backendConfigURL = fields["backend config url"].flatMap(URL.init(string:))

        guard
            let email,
            let password,
            let backendConfigURL,
            !email.isEmpty,
            !password.isEmpty
        else {
            return nil
        }

        self.email = email
        self.username = username.flatMap { $0.isEmpty ? nil : $0 }
        self.password = password
        self.backendConfigURL = backendConfigURL
    }

}
