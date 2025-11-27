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

    public static let analytics = WireTaggedLogger("analytics")
    public static let apiMigration = WireTaggedLogger("api-migration")
    public static let appDelegate = WireTaggedLogger("AppDelegate")
    public static let appLock = WireTaggedLogger("AppLock")
    public static let appState = WireTaggedLogger("AppState")
    public static let appVersionMigration = WireTaggedLogger("api-version-migration")
    public static let assets = WireTaggedLogger("assets")
    public static let authentication = WireTaggedLogger("authentication")
    public static let avs = WireTaggedLogger("avs")
    public static let backend = WireTaggedLogger("backend")
    public static let backgroundActivity = WireTaggedLogger("background-activity")
    public static let badgeCount = WireTaggedLogger("badge-count")
    public static let calling = WireTaggedLogger("calling")
    public static let conversation = WireTaggedLogger("conversation")
    public static let coreCrypto = WireTaggedLogger("core-crypto")
    public static let e2ei = WireTaggedLogger("end-to-end-identity")
    public static let ear = WireTaggedLogger("encryption-at-rest")
    public static let environment = WireTaggedLogger("environment")
    public static let eventProcessing = WireTaggedLogger("event-processing")
    public static let featureConfigs = WireTaggedLogger("feature-configurations")
    public static let individualToTeamMigration = WireTaggedLogger("individual-to-team-migration")
    public static let keychain = WireTaggedLogger("keychain")
    public static let localStorage = WireTaggedLogger("local-storage")
    public static let mainCoordinator = WireTaggedLogger("main-coordinator")
    public static let messageProcessing = WireTaggedLogger("message-processing")
    public static let messaging = WireTaggedLogger("messaging")
    public static let mls = WireTaggedLogger("mls")
    public static let network = WireTaggedLogger("network")
    public static let notifications = WireTaggedLogger("notifications")
    public static let performance = WireTaggedLogger("performance")
    public static let proteus = WireTaggedLogger("proteus")
    public static let push = WireTaggedLogger("push")
    public static let pushChannel = WireTaggedLogger("push-channel")
    public static let search = WireTaggedLogger("search")
    public static let session = WireTaggedLogger("session")
    public static let sessionManager = WireTaggedLogger("SessionManager")
    public static let shareExtension = WireTaggedLogger("share-extension")
    public static let supportedProtocols = WireTaggedLogger("supported-protocols")
    public static let sync = WireTaggedLogger("sync")
    public static let system = WireTaggedLogger("system", additionalAttributes: [
        .processID("\(ProcessInfo.processInfo.processIdentifier)"),
        .processName(ProcessInfo.processInfo.processName)
    ])
    public static let timePoint = WireTaggedLogger("timePoint")
    public static let ui = WireTaggedLogger("UI")
    public static let updateEvent = WireTaggedLogger("update-event")
    public static let userClient = WireTaggedLogger("user-client")
    public static let webSocket = WireTaggedLogger("websocket")
    public static let wireCells = WireTaggedLogger("wire-cells")

    // MARK: - Setup

    /// This method must be called very early on app start, before any other interaction with ``WireLogger``.

    public static func setup(_ logHandler: any WireLogHandlerProtocol) {
        precondition(Thread.isMainThread)
        guard self.logHandler == nil else {
            fatalError("WireLogger is already set up")
        }
        self.logHandler = logHandler
    }

    public private(set) nonisolated(unsafe) static var logHandler: (any WireLogHandlerProtocol)!

    // MARK: Helper

    private static func WireTaggedLogger(
        _ tag: WireLogTag,
        additionalAttributes: [WireLogAttribute] = []
    ) -> WireTaggedLogger {
        .init(
            tag: tag,
            handler: logHandler,
            additionalAttributes: additionalAttributes
        )
    }

}
