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

public enum WireLogger {

    /// This method must be called very early on app start, before any other interaction with ``WireLogger``.

    public static func setup(_ logHandler: any WireLogHandlerProtocol) {
        precondition(Thread.isMainThread)
        guard self.logHandler == nil else {
            fatalError("WireLogger is already set up")
        }
        self.logHandler = logHandler
    }

    nonisolated(unsafe) public private(set) static var logHandler: (any WireLogHandlerProtocol)!

    public static let analytics = WireTaggedLogger(tag: "analytics", handler: logHandler)
    public static let apiMigration = WireTaggedLogger(tag: "api-migration", handler: logHandler)
    public static let appVersionMigration = WireTaggedLogger(tag: "api-version-migration", handler: logHandler)
    public static let appState = WireTaggedLogger(tag: "AppState", handler: logHandler)
    public static let appDelegate = WireTaggedLogger(tag: "AppDelegate", handler: logHandler)
    public static let appLock = WireTaggedLogger(tag: "AppLock", handler: logHandler)
    public static let assets = WireTaggedLogger(tag: "assets", handler: logHandler)
    public static let authentication = WireTaggedLogger(tag: "authentication", handler: logHandler)
    public static let backend = WireTaggedLogger(tag: "backend", handler: logHandler)
    public static let backgroundActivity = WireTaggedLogger(tag: "background-activity", handler: logHandler)
    public static let badgeCount = WireTaggedLogger(tag: "badge-count", handler: logHandler)
    public static let calling = WireTaggedLogger(tag: "calling", handler: logHandler)
    public static let conversation = WireTaggedLogger(tag: "conversation", handler: logHandler)
    public static let coreCrypto = WireTaggedLogger(tag: "core-crypto", handler: logHandler)
    public static let e2ei = WireTaggedLogger(tag: "end-to-end-identity", handler: logHandler)
    public static let ear = WireTaggedLogger(tag: "encryption-at-rest", handler: logHandler)
    public static let environment = WireTaggedLogger(tag: "environment", handler: logHandler)
    public static let featureConfigs = WireTaggedLogger(tag: "feature-configurations", handler: logHandler)
    public static let individualToTeamMigration = WireTaggedLogger(tag: "individual-to-team-migration", handler: logHandler)
    public static let keychain = WireTaggedLogger(tag: "keychain", handler: logHandler)
    public static let localStorage = WireTaggedLogger(tag: "local-storage", handler: logHandler)
    public static let mainCoordinator = WireTaggedLogger(tag: "main-coordinator", handler: logHandler)
    public static let messaging = WireTaggedLogger(tag: "messaging", handler: logHandler)
    public static let mls = WireTaggedLogger(tag: "mls", handler: logHandler)
    public static let notifications = WireTaggedLogger(tag: "notifications", handler: logHandler)
    public static let performance = WireTaggedLogger(tag: "performance", handler: logHandler)
    public static let push = WireTaggedLogger(tag: "push", handler: logHandler)
    public static let pushChannel = WireTaggedLogger(tag: "push-channel", handler: logHandler)
    public static let webSocket = WireTaggedLogger(tag: "websocket", handler: logHandler)
    public static let proteus = WireTaggedLogger(tag: "proteus", handler: logHandler)
    public static let session = WireTaggedLogger(tag: "session", handler: logHandler)
    public static let sessionManager = WireTaggedLogger(tag: "SessionManager", handler: logHandler)
    public static let shareExtension = WireTaggedLogger(tag: "share-extension", handler: logHandler)
    public static let sync = WireTaggedLogger(tag: "sync", handler: logHandler)
    public static let system = WireTaggedLogger(tag: "system", handler: logHandler)
    public static let timePoint = WireTaggedLogger(tag: "timePoint", handler: logHandler)
    public static let ui = WireTaggedLogger(tag: "UI", handler: logHandler)
    public static let updateEvent = WireTaggedLogger(tag: "update-event", handler: logHandler)
    public static let userClient = WireTaggedLogger(tag: "user-client", handler: logHandler)
    public static let network = WireTaggedLogger(tag: "network", handler: logHandler)
    public static let eventProcessing = WireTaggedLogger(tag: "event-processing", handler: logHandler)
    public static let messageProcessing = WireTaggedLogger(tag: "message-processing", handler: logHandler)
    public static let avs = WireTaggedLogger(tag: "avs", handler: logHandler)
    public static let supportedProtocols = WireTaggedLogger(tag: "supported-protocols", handler: logHandler)
    public static let search = WireTaggedLogger(tag: "search", handler: logHandler)
    public static let wireCells = WireTaggedLogger(tag: "wire-cells", handler: logHandler)

}
