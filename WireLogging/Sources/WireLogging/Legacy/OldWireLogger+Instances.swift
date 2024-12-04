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

    static let apiMigration = OldWireLogger(tag: "api-migration")
    static let appState = OldWireLogger(tag: "AppState")
    static let appDelegate = OldWireLogger(tag: "AppDelegate")
    static let appLock = OldWireLogger(tag: "AppLock")
    static let assets = OldWireLogger(tag: "assets")
    static let authentication = OldWireLogger(tag: "authentication")
    static let backgroundActivity = OldWireLogger(tag: "background-activity")
    static let badgeCount = OldWireLogger(tag: "badge-count")
    static let backend = OldWireLogger(tag: "backend")
    static let calling = OldWireLogger(tag: "calling")
    static let conversation = OldWireLogger(tag: "conversation")
    static let coreCrypto = OldWireLogger(tag: "core-crypto")
    static let e2ei = OldWireLogger(tag: "end-to-end-identity")
    static let ear = OldWireLogger(tag: "encryption-at-rest")
    static let environment = OldWireLogger(tag: "environment")
    static let featureConfigs = OldWireLogger(tag: "feature-configurations")
    static let keychain = OldWireLogger(tag: "keychain")
    static let localStorage = OldWireLogger(tag: "local-storage")
    static let mainCoordinator = OldWireLogger(tag: "main-coordinator")
    static let messaging = OldWireLogger(tag: "messaging")
    static let mls = OldWireLogger(tag: "mls")
    static let notifications = OldWireLogger(tag: "notifications")
    static let performance = OldWireLogger(tag: "performance")
    static let push = OldWireLogger(tag: "push")
    static let pushChannel = OldWireLogger(tag: "push-channel")
    static let proteus = OldWireLogger(tag: "proteus")
    static let session = OldWireLogger(tag: "session")
    static let sessionManager = OldWireLogger(tag: "SessionManager")
    static let shareExtension = OldWireLogger(tag: "share-extension")
    static let sync = OldWireLogger(tag: "sync")
    static let system = OldWireLogger(tag: "system")
    static let timePoint = OldWireLogger(tag: "timePoint")
    static let ui = OldWireLogger(tag: "UI")
    static let updateEvent = OldWireLogger(tag: "update-event")
    static let userClient = OldWireLogger(tag: "user-client")
    static let network = OldWireLogger(tag: "network")
    static let eventProcessing = OldWireLogger(tag: "event-processing")
    static let messageProcessing = OldWireLogger(tag: "message-processing")
    static let avs = OldWireLogger(tag: "avs")
    static let analytics = OldWireLogger(tag: "analytics")
    static let supportedProtocols = OldWireLogger(tag: "supported-protocols")
}
