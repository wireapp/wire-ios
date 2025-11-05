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

public enum WireLogger {

    /// This method must be called very early on app start, before any other interaction with ``WireLogger``.

    @MainActor
    static func setup(_ logHandler: any WireLogHandlerProtocol) {
        guard self.logHandler == nil else {
            fatalError("WireLogger is already set up")
        }
        self.logHandler = logHandler
    }

    nonisolated(unsafe) private static var logHandler: (any WireLogHandlerProtocol)!

    static let apiMigration = WireTaggedLogger(tag: "api-migration", handler: logHandler)
    static let appVersionMigration = WireTaggedLogger(tag: "api-version-migration", handler: logHandler)
    static let appState = WireTaggedLogger(tag: "AppState", handler: logHandler)
    static let appDelegate = WireTaggedLogger(tag: "AppDelegate", handler: logHandler)
    static let appLock = WireTaggedLogger(tag: "AppLock", handler: logHandler)
    static let assets = WireTaggedLogger(tag: "assets", handler: logHandler)
    static let authentication = WireTaggedLogger(tag: "authentication", handler: logHandler)
    static let backend = WireTaggedLogger(tag: "backend", handler: logHandler)
    static let backupExport = WireTaggedLogger(tag: "backup-export", handler: logHandler)
    static let backupImport = WireTaggedLogger(tag: "backup-import", handler: logHandler)
    static let backgroundActivity = WireTaggedLogger(tag: "background-activity", handler: logHandler)
    static let badgeCount = WireTaggedLogger(tag: "badge-count", handler: logHandler)
    static let calling = WireTaggedLogger(tag: "calling", handler: logHandler)
    static let conversation = WireTaggedLogger(tag: "conversation", handler: logHandler)
    static let coreCrypto = WireTaggedLogger(tag: "core-crypto", handler: logHandler)
    static let e2ei = WireTaggedLogger(tag: "end-to-end-identity", handler: logHandler)
    static let ear = WireTaggedLogger(tag: "encryption-at-rest", handler: logHandler)
    static let environment = WireTaggedLogger(tag: "environment", handler: logHandler)
    static let featureConfigs = WireTaggedLogger(tag: "feature-configurations", handler: logHandler)
    static let individualToTeamMigration = WireTaggedLogger(tag: "individual-to-team-migration", handler: logHandler)
    static let keychain = WireTaggedLogger(tag: "keychain", handler: logHandler)
    static let localStorage = WireTaggedLogger(tag: "local-storage", handler: logHandler)
    static let mainCoordinator = WireTaggedLogger(tag: "main-coordinator", handler: logHandler)
    static let messaging = WireTaggedLogger(tag: "messaging", handler: logHandler)
    static let mls = WireTaggedLogger(tag: "mls", handler: logHandler)
    static let notifications = WireTaggedLogger(tag: "notifications", handler: logHandler)
    static let performance = WireTaggedLogger(tag: "performance", handler: logHandler)
    static let push = WireTaggedLogger(tag: "push", handler: logHandler)
    static let pushChannel = WireTaggedLogger(tag: "push-channel", handler: logHandler)
    static let webSocket = WireTaggedLogger(tag: "websocket", handler: logHandler)
    static let proteus = WireTaggedLogger(tag: "proteus", handler: logHandler)
    static let session = WireTaggedLogger(tag: "session", handler: logHandler)
    static let sessionManager = WireTaggedLogger(tag: "SessionManager", handler: logHandler)
    static let shareExtension = WireTaggedLogger(tag: "share-extension", handler: logHandler)
    static let sync = WireTaggedLogger(tag: "sync", handler: logHandler)
    static let system = WireTaggedLogger(tag: "system", handler: logHandler)
    static let timePoint = WireTaggedLogger(tag: "timePoint", handler: logHandler)
    static let ui = WireTaggedLogger(tag: "UI", handler: logHandler)
    static let updateEvent = WireTaggedLogger(tag: "update-event", handler: logHandler)
    static let userClient = WireTaggedLogger(tag: "user-client", handler: logHandler)
    static let network = WireTaggedLogger(tag: "network", handler: logHandler)
    static let eventProcessing = WireTaggedLogger(tag: "event-processing", handler: logHandler)
    static let messageProcessing = WireTaggedLogger(tag: "message-processing", handler: logHandler)
    static let avs = WireTaggedLogger(tag: "avs", handler: logHandler)
    static let analytics = WireTaggedLogger(tag: "analytics", handler: logHandler)
    static let supportedProtocols = WireTaggedLogger(tag: "supported-protocols", handler: logHandler)
    static let search = WireTaggedLogger(tag: "search", handler: logHandler)
    static let wireCells = WireTaggedLogger(tag: "wire-cells", handler: logHandler)

}
