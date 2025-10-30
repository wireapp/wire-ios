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

extension WireLogger {

    nonisolated(unsafe) private static var providerBuilder: ((Tag) -> [any WireLoggingProvider])!

    /// This method is supposed to be called very early on app start, before any other interaction with ``WireLogger``.
    public static func setup(_ providerBuilder: @escaping (Tag) -> [any WireLoggingProvider]) {
        guard self.providerBuilder == nil else {
            fatalError("WireLogger is already set up")
        }
        self.providerBuilder = providerBuilder
    }

    public static let apiMigration = WireLogger(tag: "api-migration", providerBuilder)
    public static let appState = WireLogger(tag: "AppState", providerBuilder)
    public static let appDelegate = WireLogger(tag: "AppDelegate", providerBuilder)
    public static let appLock = WireLogger(tag: "AppLock", providerBuilder)
    public static let assets = WireLogger(tag: "assets", providerBuilder)
    public static let authentication = WireLogger(tag: "authentication", providerBuilder)
    public static let backgroundActivity = WireLogger(tag: "background-activity", providerBuilder)
    public static let badgeCount = WireLogger(tag: "badge-count", providerBuilder)
    public static let backend = WireLogger(tag: "backend", providerBuilder)
    public static let calling = WireLogger(tag: "calling", providerBuilder)
    public static let conversation = WireLogger(tag: "conversation", providerBuilder)
    public static let coreCrypto = WireLogger(tag: "core-crypto", providerBuilder)
    public static let e2ei = WireLogger(tag: "end-to-end-identity", providerBuilder)
    public static let ear = WireLogger(tag: "encryption-at-rest", providerBuilder)
    public static let environment = WireLogger(tag: "environment", providerBuilder)
    public static let featureConfigs = WireLogger(tag: "feature-configurations", providerBuilder)
    public static let keychain = WireLogger(tag: "keychain", providerBuilder)
    public static let localStorage = WireLogger(tag: "local-storage", providerBuilder)
    public static let mainCoordinator = WireLogger(tag: "main-coordinator", providerBuilder)
    public static let messaging = WireLogger(tag: "messaging", providerBuilder)
    public static let mls = WireLogger(tag: "mls", providerBuilder)
    public static let notifications = WireLogger(tag: "notifications", providerBuilder)
    public static let performance = WireLogger(tag: "performance", providerBuilder)
    public static let push = WireLogger(tag: "push", providerBuilder)
    public static let pushChannel = WireLogger(tag: "push-channel", providerBuilder)
    public static let proteus = WireLogger(tag: "proteus", providerBuilder)
    public static let session = WireLogger(tag: "session", providerBuilder)
    public static let sessionManager = WireLogger(tag: "SessionManager", providerBuilder)
    public static let shareExtension = WireLogger(tag: "share-extension", providerBuilder)
    public static let sync = WireLogger(tag: "sync", providerBuilder)
    public static let system = WireLogger(tag: "system", providerBuilder)
    public static let timePoint = WireLogger(tag: "timePoint", providerBuilder)
    public static let ui = WireLogger(tag: "UI", providerBuilder)
    public static let updateEvent = WireLogger(tag: "update-event", providerBuilder)
    public static let userClient = WireLogger(tag: "user-client", providerBuilder)
    public static let network = WireLogger(tag: "network", providerBuilder)
    public static let eventProcessing = WireLogger(tag: "event-processing", providerBuilder)
    public static let messageProcessing = WireLogger(tag: "message-processing", providerBuilder)
    public static let avs = WireLogger(tag: "avs", providerBuilder)
    public static let analytics = WireLogger(tag: "analytics", providerBuilder)
    public static let supportedProtocols = WireLogger(tag: "supported-protocols", providerBuilder)
}

private extension WireLogger {
    init(tag: Tag, _ providersBuilder: (Tag) -> [any WireLoggingProvider]) {
        self.init(tag: tag, providers: providersBuilder(tag))
    }
}
