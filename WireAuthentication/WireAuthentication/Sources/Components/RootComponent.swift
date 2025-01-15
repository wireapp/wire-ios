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

import NeedleFoundation
import SwiftUI
import WireAPI
internal import WireAuthenticationUI

class RootComponent: BootstrapComponent {

    private let backendURL: URL
    private let minTLSVersion: TLSVersion
    public let apiVersion: APIVersion

    public init(
        backendURL: URL,
        minTLSVersion: TLSVersion,
        apiVersion: APIVersion
    ) {
        self.backendURL = backendURL
        self.minTLSVersion = minTLSVersion
        self.apiVersion = apiVersion
    }

    private var serverTrustValidator: ServerTrustValidator {
        shared {
            ServerTrustValidator(pinnedKeys: [])
        }
    }

    private var urlSessionConfigurationFactory: URLSessionConfigurationFactory {
        shared {
            URLSessionConfigurationFactory(
                minTLSVersion: minTLSVersion,
                proxySettings: nil
            )
        }
    }

    public var networkService: NetworkService {
        shared {
            let service = NetworkService(
                baseURL: backendURL,
                serverTrustValidator: serverTrustValidator
            )
            let config = urlSessionConfigurationFactory.makeRESTAPISessionConfiguration()
            let session = URLSession(configuration: config, delegate: service, delegateQueue: nil)
            service.configure(with: session)
            return service
        }
    }

    @MainActor
    public var router: Router {
        rootViewModel
    }

    @MainActor
    private var rootViewModel: RootViewModel {
        shared {
            RootViewModel()
        }
    }

    @MainActor
    var rootView: some View {
        RootView(
            viewModel: rootViewModel,
            builder: determineAuthMethodComponent
        )
    }

    // MARK: - Children

    var determineAuthMethodComponent: DetermineAuthMethodComponent {
        DetermineAuthMethodComponent(parent: self)
    }

}
