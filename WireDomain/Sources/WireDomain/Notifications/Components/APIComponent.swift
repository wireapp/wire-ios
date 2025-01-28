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
import WireAPI
import WireDataModel

protocol UpdateEventsAPIProvider {
    var updateEventsAPI: any UpdateEventsAPI { get async }
}

/// Provides API objects.
final class APIComponent: Component<EmptyDependency>, UpdateEventsAPIProvider {
    private let selfClientID: String

    init(
        parent: any Scope,
        selfClientID: String
    ) {
        self.selfClientID = selfClientID
        super.init(parent: parent)
    }

    var updateEventsAPI: any UpdateEventsAPI {
        get async {
            UpdateEventsAPIBuilder(
                apiService: await apiService
            ).makeAPI(for: apiVersion)
        }
    }

    var selfUserAPI: any SelfUserAPI {
        get async {
            SelfUserAPIBuilder(
                apiService: await apiService
            ).makeAPI(for: apiVersion)
        }
    }

    var usersAPI: any UsersAPI {
        get async {
            UsersAPIBuilder(
                apiService: await apiService
            ).makeAPI(for: apiVersion)
        }
    }

    // MARK: - Private

    private var apiService: any APIServiceProtocol {
        get async {
            APIService(
                networkService: await networkService,
                authenticationManager: await authenticationManager
            )
        }
    }

    private var apiVersion: WireAPI.APIVersion {
        let key = "SelectedAPIVersion"
        guard coreStorageComponent.userDefaults.object(forKey: key) != nil else {
            fatalError("API version not found")
        }

        let storedValue = coreStorageComponent.userDefaults.integer(forKey: key)
        let legacyAPIVersion = APIVersion(rawValue: Int32(storedValue))

        guard let legacyAPIVersion,
              let apiVersion = WireAPI.APIVersion(rawValue: UInt(legacyAPIVersion.rawValue)) else {
            return .v0
        }

        return apiVersion
    }

    private var networkService: NetworkService {
        get async {
            let service = NetworkService(
                baseURL: await backendEnvironment.url,
                serverTrustValidator: ServerTrustValidator(
                    pinnedKeys: await backendEnvironment.pinnedKeys
                )
            )

            let minTLSVersion = WireAPI.TLSVersion.minVersionFrom(minTLSVersion)
            let config = URLSessionConfigurationFactory(
                minTLSVersion: minTLSVersion,
                proxySettings: await proxySettings
            )
            let session = URLSession(
                configuration: config.makeRESTAPISessionConfiguration(),
                delegate: service,
                delegateQueue: nil
            )
            service.configure(with: session)

            return service
        }
    }

    private var authenticationManager: any AuthenticationManagerProtocol {
        get async {
            AuthenticationManager(
                clientID: selfClientID,
                cookieStorage: coreStorageComponent.cookieStorage,
                networkService: await networkService
            )
        }
    }

    private var backendEnvironment: WireAPI.BackendEnvironment {
        get async {
            await environmentComponent.backendEnvironment
        }
    }

    private var proxySettings: ProxySettings? {
        get async {
            await environmentComponent.proxySettings
        }
    }

    private var minTLSVersion: String? {
        environmentComponent.appMainBundle.infoForKey("MinTLSVersion")
    }

    // MARK: - Child components

    var environmentComponent: EnvironmentComponent {
        EnvironmentComponent(parent: self)
    }

    var coreStorageComponent: CoreStorageComponent {
        CoreStorageComponent(parent: self)
    }

}
