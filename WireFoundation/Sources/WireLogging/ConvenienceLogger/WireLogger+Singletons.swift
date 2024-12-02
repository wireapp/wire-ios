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

    nonisolated(unsafe) private static var loggingSystem: (any WireLoggingSystem)!

    /// This method is supposed to be called very early on app start, before any other interaction with ``WireLogger``.
    @MainActor
    public static func setup(_ loggingSystem: any WireLoggingSystem) {
        guard self.loggingSystem == nil else {
            fatalError("WireLogger is already set up")
        }

        self.loggingSystem = loggingSystem
    }

    static let apiMigration = WireLogger(tag: "api-migration") { loggingSystem }
    static let appState = WireLogger(tag: "AppState") { loggingSystem }
    static let appDelegate = WireLogger(tag: "AppDelegate") { loggingSystem }
    static let appLock = WireLogger(tag: "AppLock") { loggingSystem }
    static let assets = WireLogger(tag: "assets") { loggingSystem }
    static let authentication = WireLogger(tag: "authentication") { loggingSystem }
    static let backgroundActivity = WireLogger(tag: "background-activity") { loggingSystem }
    static let badgeCount = WireLogger(tag: "badge-count") { loggingSystem }
    static let backend = WireLogger(tag: "backend") { loggingSystem }
    static let calling = WireLogger(tag: "calling") { loggingSystem }
    static let conversation = WireLogger(tag: "conversation") { loggingSystem }
    static let coreCrypto = WireLogger(tag: "core-crypto") { loggingSystem }
    static let e2ei = WireLogger(tag: "end-to-end-identity") { loggingSystem }
    static let ear = WireLogger(tag: "encryption-at-rest") { loggingSystem }
    static let environment = WireLogger(tag: "environment") { loggingSystem }
    static let featureConfigs = WireLogger(tag: "feature-configurations") { loggingSystem }
    static let keychain = WireLogger(tag: "keychain") { loggingSystem }
    static let localStorage = WireLogger(tag: "local-storage") { loggingSystem }
    static let mainCoordinator = WireLogger(tag: "main-coordinator") { loggingSystem }
    static let messaging = WireLogger(tag: "messaging") { loggingSystem }
    static let mls = WireLogger(tag: "mls") { loggingSystem }
    static let notifications = WireLogger(tag: "notifications") { loggingSystem }
    static let performance = WireLogger(tag: "performance") { loggingSystem }
    static let push = WireLogger(tag: "push") { loggingSystem }
    static let pushChannel = WireLogger(tag: "push-channel") { loggingSystem }
    static let proteus = WireLogger(tag: "proteus") { loggingSystem }
    static let session = WireLogger(tag: "session") { loggingSystem }
    static let sessionManager = WireLogger(tag: "SessionManager") { loggingSystem }
    static let shareExtension = WireLogger(tag: "share-extension") { loggingSystem }
    static let sync = WireLogger(tag: "sync") { loggingSystem }
    static let system = WireLogger(tag: "system") { loggingSystem }
    static let timePoint = WireLogger(tag: "timePoint") { loggingSystem }
    static let ui = WireLogger(tag: "UI") { loggingSystem }
    static let updateEvent = WireLogger(tag: "update-event") { loggingSystem }
    static let userClient = WireLogger(tag: "user-client") { loggingSystem }
    static let network = WireLogger(tag: "network") { loggingSystem }
    static let eventProcessing = WireLogger(tag: "event-processing") { loggingSystem }
    static let messageProcessing = WireLogger(tag: "message-processing") { loggingSystem }
    static let avs = WireLogger(tag: "avs") { loggingSystem }
    static let analytics = WireLogger(tag: "analytics") { loggingSystem }
    static let supportedProtocols = WireLogger(tag: "supported-protocols") { loggingSystem }
}
