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
import WireDataModel
import WireNetwork
import WireNetworkInterface

final class NotificationServiceExtensionFlow: BootstrapComponent {

    enum Failure: Error {
        case missingAppGroupID
    }

    public let contentHandler: (UNNotificationContent) -> Void
    public let applicationIdentifier: String
    public let applicationContainer: URL
    public let accountManager: AccountManager

    public var sharedUserDefaults: UserDefaults {
        UserDefaults(suiteName: applicationIdentifier)!
    }

    init(
        contentHandler: @escaping (UNNotificationContent) -> Void
    ) throws {
        self.contentHandler = contentHandler

        let infoDictionary = Bundle.main.infoDictionary
        guard let appGroupID = infoDictionary?["WireGroupId"] as? String else {
            throw Failure.missingAppGroupID
        }

        let applicationIdentifier = "group.\(appGroupID)"
        let applicationContainer = FileManager.sharedContainerDirectory(
            for: applicationIdentifier
        )

        self.applicationIdentifier = applicationIdentifier
        self.applicationContainer = applicationContainer
        self.accountManager = try AccountManager(sharedDirectory: applicationContainer)
    }

    func start(request: UNNotificationRequest) async throws {
        try await processNotificationRequestStep.process(
            request: request
        )
    }

    // MARK: - Children

    var processNotificationRequestStep: ProcessNotificationRequestStep {
        ProcessNotificationRequestStep(parent: self)
    }

    public var backendEnvironment: BackendEnvironment2 {
        BackendEnvironment2(legacyBackendEnvironment)
    }

    public var minTLSVersion: WireNetwork.TLSVersion {
        if let version = appMainBundle.infoForKey("MinTLSVersion") {
            TLSVersion(version) ?? .v1_2
        } else {
            .v1_2
        }
    }

    public var preferredAPIVersion: WireNetwork.APIVersion? {
        BackendInfo.preferredAPIVersion.flatMap {
            APIVersion(rawValue: UInt($0.rawValue))
        }
    }

    private var legacyBackendEnvironment: WireDataModel.BackendEnvironment {
        let environmentType = if let override = sharedUserDefaults.string(
            forKey: "BackendEnvironmentTypeOverrideKey"
        ) {
            EnvironmentType(stringValue: override)
        } else {
            EnvironmentType(userDefaults: sharedUserDefaults)
        }

        guard let backendEnvironment = WireTransport.BackendEnvironment(
            userDefaults: sharedUserDefaults,
            configurationBundle: backendBundle,
            environmentType: environmentType
        ) else {
            fatal("Malformed backend configuration data")
        }

        return backendEnvironment
    }

    var appMainBundle: Bundle {
        let mainBundle: Bundle
        let runningInExtension = Bundle.main.bundlePath.hasSuffix(".appex")

        if runningInExtension {
            let extensionBundleURL = Bundle.main.bundleURL
            let mainAppBundleURL = extensionBundleURL.deletingLastPathComponent().deletingLastPathComponent()
            guard let bundle = Bundle(url: mainAppBundleURL) else { fatal("Failed to find main app bundle") }
            mainBundle = bundle
        } else {
            mainBundle = .main
        }
        return mainBundle
    }

    var backendBundle: Bundle {
        guard let backendBundlePath = appMainBundle.path(
            forResource: "Backend",
            ofType: "bundle"
        ) else {
            fatal("Could not find backend.bundle")
        }

        guard let bundle = Bundle(path: backendBundlePath) else {
            fatal("Could not load backend.bundle")
        }

        return bundle
    }
}

public extension BackendEnvironment2 {

    init(_ legacyEnvironment: WireTransport.BackendEnvironment) {
        let environmentType = switch legacyEnvironment.environmentType.value {
        case .default:
            BackendEnvironment2.EnvironmentType.default
        case .staging:
            BackendEnvironment2.EnvironmentType.staging
        case .anta:
            BackendEnvironment2.EnvironmentType.anta
        case .bella:
            BackendEnvironment2.EnvironmentType.bella
        case .chala:
            BackendEnvironment2.EnvironmentType.chala
        case .diya:
            BackendEnvironment2.EnvironmentType.diya
        case .elna:
            BackendEnvironment2.EnvironmentType.elna
        case .foma:
            BackendEnvironment2.EnvironmentType.foma
        case let .custom(url: url):
            BackendEnvironment2.EnvironmentType.custom(url: url)
        }

        let endpoints = Endpoints(
            restAPIURL: legacyEnvironment.backendURL,
            websocketURL: legacyEnvironment.backendWSURL,
            blacklistURL: legacyEnvironment.blackListURL,
            teamsURL: legacyEnvironment.teamsURL,
            accountsURL: legacyEnvironment.accountsURL,
            websiteURL: legacyEnvironment.websiteURL,
            countlyURL: legacyEnvironment.countlyURL
        )

        let pinnedKeys = legacyEnvironment.trustData.map {
            PinnedKey($0)
        }

        let proxyConfig = legacyEnvironment.proxy.map {
            ProxyConfig(
                host: $0.host,
                port: $0.port,
                needsAuthentication: $0.needsAuthentication
            )
        }

        let config = BackendEnvironment2.Config(
            endpoints: endpoints,
            pinnedKeys: pinnedKeys,
            proxyConfig: proxyConfig
        )

        self.init(
            title: legacyEnvironment.title,
            environmentType: environmentType,
            config: config
        )
    }

}

private extension PinnedKey {

    init(_ trustData: TrustData) {
        self.init(
            key: trustData.certificateKey,
            rawKey: trustData.rawCertificateKey,
            hosts: trustData.hosts.map { host in
                switch host.rule {
                case .equals:
                    .equals(host.value)
                case .endsWith:
                    .endsWith(host.value)
                }
            }
        )
    }

}
