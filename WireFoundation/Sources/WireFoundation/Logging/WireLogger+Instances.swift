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
    // TODO: [WPB-11890] try to delete nonisolated(unsafe)
    nonisolated(unsafe) static let apiMigration = WireLogger(tag: "api-migration")
    nonisolated(unsafe) static let appState = WireLogger(tag: "AppState")
    nonisolated(unsafe) static let appDelegate = WireLogger(tag: "AppDelegate")
    nonisolated(unsafe) static let appLock = WireLogger(tag: "AppLock")
    nonisolated(unsafe) static let assets = WireLogger(tag: "assets")
    nonisolated(unsafe) static let authentication = WireLogger(tag: "authentication")
    nonisolated(unsafe) static let backgroundActivity = WireLogger(tag: "background-activity")
    nonisolated(unsafe) static let badgeCount = WireLogger(tag: "badge-count")
    nonisolated(unsafe) static let backend = WireLogger(tag: "backend")
    nonisolated(unsafe) static let calling = WireLogger(tag: "calling")
    nonisolated(unsafe) static let conversation = WireLogger(tag: "conversation")
    nonisolated(unsafe) static let coreCrypto = WireLogger(tag: "core-crypto")
    nonisolated(unsafe) static let e2ei = WireLogger(tag: "end-to-end-identity")
    nonisolated(unsafe) static let ear = WireLogger(tag: "encryption-at-rest")
    nonisolated(unsafe) static let environment = WireLogger(tag: "environment")
    nonisolated(unsafe) static let featureConfigs = WireLogger(tag: "feature-configurations")
    nonisolated(unsafe) static let keychain = WireLogger(tag: "keychain")
    nonisolated(unsafe) static let localStorage = WireLogger(tag: "local-storage")
    nonisolated(unsafe) static let mainCoordinator = WireLogger(tag: "main-coordinator")
    nonisolated(unsafe) static let messaging = WireLogger(tag: "messaging")
    nonisolated(unsafe) static let mls = WireLogger(tag: "mls")
    nonisolated(unsafe) static let notifications = WireLogger(tag: "notifications")
    nonisolated(unsafe) static let performance = WireLogger(tag: "performance")
    nonisolated(unsafe) static let push = WireLogger(tag: "push")
    nonisolated(unsafe) static let pushChannel = WireLogger(tag: "push-channel")
    nonisolated(unsafe) static let proteus = WireLogger(tag: "proteus")
    nonisolated(unsafe) static let session = WireLogger(tag: "session")
    nonisolated(unsafe) static let sessionManager = WireLogger(tag: "SessionManager")
    nonisolated(unsafe) static let shareExtension = WireLogger(tag: "share-extension")
    nonisolated(unsafe) static let sync = WireLogger(tag: "sync")
    nonisolated(unsafe) static let system = WireLogger(tag: "system")
    nonisolated(unsafe) static let timePoint = WireLogger(tag: "timePoint")
    nonisolated(unsafe) static let ui = WireLogger(tag: "UI")
    nonisolated(unsafe) static let updateEvent = WireLogger(tag: "update-event")
    nonisolated(unsafe) static let userClient = WireLogger(tag: "user-client")
    nonisolated(unsafe) static let network = WireLogger(tag: "network")
    nonisolated(unsafe) static let eventProcessing = WireLogger(tag: "event-processing")
    nonisolated(unsafe) static let messageProcessing = WireLogger(tag: "message-processing")
    nonisolated(unsafe) static let avs = WireLogger(tag: "avs")
    nonisolated(unsafe) static let analytics = WireLogger(tag: "analytics")
    nonisolated(unsafe) static let supportedProtocols = WireLogger(tag: "supported-protocols")
}
