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
    public static let apiMigration = WireLogger(tag: "api-migration")
    public static let appState = WireLogger(tag: "AppState")
    public static let appDelegate = WireLogger(tag: "AppDelegate")
    public static let appLock = WireLogger(tag: "AppLock")
    public static let assets = WireLogger(tag: "assets")
    public static let authentication = WireLogger(tag: "authentication")
    public static let backgroundActivity = WireLogger(tag: "background-activity")
    public static let badgeCount = WireLogger(tag: "badge-count")
    public static let backend = WireLogger(tag: "backend")
    public static let calling = WireLogger(tag: "calling")
    public static let conversation = WireLogger(tag: "conversation")
    public static let coreCrypto = WireLogger(tag: "core-crypto")
    public static let e2ei = WireLogger(tag: "end-to-end-identity")
    public static let ear = WireLogger(tag: "encryption-at-rest")
    public static let environment = WireLogger(tag: "environment")
    public static let featureConfigs = WireLogger(tag: "feature-configurations")
    public static let keychain = WireLogger(tag: "keychain")
    public static let localStorage = WireLogger(tag: "local-storage")
    public static let mainCoordinator = WireLogger(tag: "main-coordinator")
    public static let messaging = WireLogger(tag: "messaging")
    public static let mls = WireLogger(tag: "mls")
    public static let notifications = WireLogger(tag: "notifications")
    public static let performance = WireLogger(tag: "performance")
    public static let push = WireLogger(tag: "push")
    public static let pushChannel = WireLogger(tag: "push-channel")
    public static let proteus = WireLogger(tag: "proteus")
    public static let session = WireLogger(tag: "session")
    public static let sessionManager = WireLogger(tag: "SessionManager")
    public static let shareExtension = WireLogger(tag: "share-extension")
    public static let sync = WireLogger(tag: "sync")
    public static let system = WireLogger(tag: "system")
    public static let timePoint = WireLogger(tag: "timePoint")
    public static let ui = WireLogger(tag: "UI")
    public static let updateEvent = WireLogger(tag: "update-event")
    public static let userClient = WireLogger(tag: "user-client")
    public static let network = WireLogger(tag: "network")
    public static let eventProcessing = WireLogger(tag: "event-processing")
    public static let messageProcessing = WireLogger(tag: "message-processing")
}
