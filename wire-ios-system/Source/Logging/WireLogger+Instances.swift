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

    static let apiMigration = WireLogger(tag: "api-migration")
    static let appState = WireLogger(tag: "AppState")
    static let appDelegate = WireLogger(tag: "AppDelegate")
    static let appLock = WireLogger(tag: "AppLock")
    static let assets = WireLogger(tag: "assets")
    static let authentication = WireLogger(tag: "authentication")
    static let backgroundActivity = WireLogger(tag: "background-activity")
    static let badgeCount = WireLogger(tag: "badge-count")
    static let backend = WireLogger(tag: "backend")
    static let calling = WireLogger(tag: "calling")
    static let conversation = WireLogger(tag: "conversation")
    static let coreCrypto = WireLogger(tag: "core-crypto")
    static let e2ei = WireLogger(tag: "end-to-end-identity")
    static let ear = WireLogger(tag: "encryption-at-rest")
    static let environment = WireLogger(tag: "environment")
    static let featureConfigs = WireLogger(tag: "feature-configurations")
    static let keychain = WireLogger(tag: "keychain")
    static let localStorage = WireLogger(tag: "local-storage")
    static let mainCoordinator = WireLogger(tag: "main-coordinator")
    static let messaging = WireLogger(tag: "messaging")
    static let mls = WireLogger(tag: "mls")
    static let notifications = WireLogger(tag: "notifications")
    static let performance = WireLogger(tag: "performance")
    static let push = WireLogger(tag: "push")
    static let pushChannel = WireLogger(tag: "push-channel")
    static let proteus = WireLogger(tag: "proteus")
    static let session = WireLogger(tag: "session")
    static let sessionManager = WireLogger(tag: "SessionManager")
    static let shareExtension = WireLogger(tag: "share-extension")
    static let sync = WireLogger(tag: "sync")
    static let system = WireLogger(tag: "system")
    static let timePoint = WireLogger(tag: "timePoint")
    static let ui = WireLogger(tag: "UI")
    static let updateEvent = WireLogger(tag: "update-event")
    static let userClient = WireLogger(tag: "user-client")
    static let network = WireLogger(tag: "network")
    static let eventProcessing = WireLogger(tag: "event-processing")
    static let messageProcessing = WireLogger(tag: "message-processing")
    static let analytics = WireLogger(tag: "analytics")
    static let supportedProtocols = WireLogger(tag: "supported-protocols")
}
