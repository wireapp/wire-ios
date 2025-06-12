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
import WireFoundation
import WireLogging

package final class NetworkStack {

    package let backendInfo: BackendInfo
    package let minTLSVersion: TLSVersion
    package let preferredAPIVersion: APIVersion?

    package var backendMetadata: WireAuthenticationDomain.BackendMetadata?
    package var state: NetworkState
    package var proxyCredentials: ProxyCredentials?

    package init(
        backendInfo: BackendInfo,
        minTLSVersion: TLSVersion,
        preferredAPIVersion: APIVersion?
    ) {
        self.backendInfo = backendInfo
        self.minTLSVersion = minTLSVersion
        self.preferredAPIVersion = preferredAPIVersion

        do {
            self.state = .ready(try NetworkServiceRepository.make(
                backendConfig: backendInfo.backendConfig,
                minTLSVersion: minTLSVersion,
                proxyCredentials: nil
            ))
        } catch .proxyCredentialsRequired {
            self.state = .awaitingProxyCredentials
        } catch {
            // Xcode warns that this case will never be executed, but if
            // we take it away, it complains that not all errors are handled.
        }
    }

    // MARK: - Methods

    package func setProxyCredentials(_ proxyCredentials: ProxyCredentials) throws {
        self.proxyCredentials = proxyCredentials
        state = .ready(try NetworkServiceRepository.make(
            backendConfig: backendInfo.backendConfig,
            minTLSVersion: minTLSVersion,
            proxyCredentials: proxyCredentials
        ))
    }

    // MARK: - Private

}

package enum NetworkState {

    case awaitingProxyCredentials
    case ready(NetworkServiceRepository)

}

private extension BackendConfig {

    var requiresProxyCredentials: Bool {
        proxySettings?.needsAuthentication == true
    }

}

public protocol NetworkServiceRepository {
    func executeRequest(_ request: URLRequest) async throws -> (Data, HTTPURLResponse)
}
