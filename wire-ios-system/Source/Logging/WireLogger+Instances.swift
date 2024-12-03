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

public extension OldWireLogger {

    static let apiMigration = WireLogger.with(tag: "api-migration")
    static let appState = WireLogger.with(tag: "AppState")
    static let appDelegate = WireLogger.with(tag: "AppDelegate")
    static let appLock = WireLogger.with(tag: "AppLock")
    static let assets = WireLogger.with(tag: "assets")
    static let authentication = WireLogger.with(tag: "authentication")
    static let backgroundActivity = WireLogger.with(tag: "background-activity")
    static let badgeCount = WireLogger.with(tag: "badge-count")
    static let backend = WireLogger.with(tag: "backend")
    static let calling = WireLogger.with(tag: "calling")
    static let conversation = WireLogger.with(tag: "conversation")
    static let coreCrypto = WireLogger.with(tag: "core-crypto")
    static let e2ei = WireLogger.with(tag: "end-to-end-identity")
    static let ear = WireLogger.with(tag: "encryption-at-rest")
    static let environment = WireLogger.with(tag: "environment")
    static let featureConfigs = WireLogger.with(tag: "feature-configurations")
    static let keychain = WireLogger.with(tag: "keychain")
    static let localStorage = WireLogger.with(tag: "local-storage")
    static let mainCoordinator = WireLogger.with(tag: "main-coordinator")
    static let messaging = WireLogger.with(tag: "messaging")
    static let mls = WireLogger.with(tag: "mls")
    static let notifications = WireLogger.with(tag: "notifications")
    static let performance = WireLogger.with(tag: "performance")
    static let push = WireLogger.with(tag: "push")
    static let pushChannel = WireLogger.with(tag: "push-channel")
    static let proteus = WireLogger.with(tag: "proteus")
    static let session = WireLogger.with(tag: "session")
    static let sessionManager = WireLogger.with(tag: "SessionManager")
    static let shareExtension = WireLogger.with(tag: "share-extension")
    static let sync = WireLogger.with(tag: "sync")
    static let system = WireLogger.with(tag: "system")
    static let timePoint = WireLogger.with(tag: "timePoint")
    static let ui = WireLogger.with(tag: "UI")
    static let updateEvent = WireLogger.with(tag: "update-event")
    static let userClient = WireLogger.with(tag: "user-client")
    static let network = WireLogger.with(tag: "network")
    static let eventProcessing = WireLogger.with(tag: "event-processing")
    static let messageProcessing = WireLogger.with(tag: "message-processing")
    static let avs = WireLogger.with(tag: "avs")
    static let analytics = WireLogger.with(tag: "analytics")
    static let supportedProtocols = WireLogger.with(tag: "supported-protocols")
}
