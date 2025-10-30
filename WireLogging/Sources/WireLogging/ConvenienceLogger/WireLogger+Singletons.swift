//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

public extension WireLogger {

    private nonisolated(unsafe) static var providerBuilder: ((Tag) -> [any WireLoggingProvider])!

    /// This method is supposed to be called very early on app start, before any other interaction with ``WireLogger``.
    static func setup(_ providerBuilder: @escaping (Tag) -> [any WireLoggingProvider]) {
        guard self.providerBuilder == nil else {
            fatalError("WireLogger is already set up")
        }
        self.providerBuilder = providerBuilder
    }

    static let apiMigration = WireLogger(tag: "api-migration", providerBuilder)
    static let appState = WireLogger(tag: "AppState", providerBuilder)
    static let appDelegate = WireLogger(tag: "AppDelegate", providerBuilder)
    static let appLock = WireLogger(tag: "AppLock", providerBuilder)
    static let assets = WireLogger(tag: "assets", providerBuilder)
    static let authentication = WireLogger(tag: "authentication", providerBuilder)
    static let backgroundActivity = WireLogger(tag: "background-activity", providerBuilder)
    static let badgeCount = WireLogger(tag: "badge-count", providerBuilder)
    static let backend = WireLogger(tag: "backend", providerBuilder)
    static let calling = WireLogger(tag: "calling", providerBuilder)
    static let conversation = WireLogger(tag: "conversation", providerBuilder)
    static let coreCrypto = WireLogger(tag: "core-crypto", providerBuilder)
    static let e2ei = WireLogger(tag: "end-to-end-identity", providerBuilder)
    static let ear = WireLogger(tag: "encryption-at-rest", providerBuilder)
    static let environment = WireLogger(tag: "environment", providerBuilder)
    static let featureConfigs = WireLogger(tag: "feature-configurations", providerBuilder)
    static let keychain = WireLogger(tag: "keychain", providerBuilder)
    static let localStorage = WireLogger(tag: "local-storage", providerBuilder)
    static let mainCoordinator = WireLogger(tag: "main-coordinator", providerBuilder)
    static let messaging = WireLogger(tag: "messaging", providerBuilder)
    static let mls = WireLogger(tag: "mls", providerBuilder)
    static let notifications = WireLogger(tag: "notifications", providerBuilder)
    static let performance = WireLogger(tag: "performance", providerBuilder)
    static let push = WireLogger(tag: "push", providerBuilder)
    static let pushChannel = WireLogger(tag: "push-channel", providerBuilder)
    static let proteus = WireLogger(tag: "proteus", providerBuilder)
    static let session = WireLogger(tag: "session", providerBuilder)
    static let sessionManager = WireLogger(tag: "SessionManager", providerBuilder)
    static let shareExtension = WireLogger(tag: "share-extension", providerBuilder)
    static let sync = WireLogger(tag: "sync", providerBuilder)
    static let system = WireLogger(tag: "system", providerBuilder)
    static let timePoint = WireLogger(tag: "timePoint", providerBuilder)
    static let ui = WireLogger(tag: "UI", providerBuilder)
    static let updateEvent = WireLogger(tag: "update-event", providerBuilder)
    static let userClient = WireLogger(tag: "user-client", providerBuilder)
    static let network = WireLogger(tag: "network", providerBuilder)
    static let eventProcessing = WireLogger(tag: "event-processing", providerBuilder)
    static let messageProcessing = WireLogger(tag: "message-processing", providerBuilder)
    static let avs = WireLogger(tag: "avs", providerBuilder)
    static let analytics = WireLogger(tag: "analytics", providerBuilder)
    static let supportedProtocols = WireLogger(tag: "supported-protocols", providerBuilder)
}

private extension WireLogger {
    init(tag: Tag, _ providersBuilder: (Tag) -> [any WireLoggingProvider]) {
        self.init(tag: tag, providers: providersBuilder(tag))
    }
}
