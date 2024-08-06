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

    private static let provider = AggregatedLogger()

    static let apiMigration = WireLogger(tag: "api-migration", provider: provider)
    static let appState = WireLogger(tag: "AppState", provider: provider)
    static let appDelegate = WireLogger(tag: "AppDelegate", provider: provider)
    static let appLock = WireLogger(tag: "AppLock", provider: provider)
    static let assets = WireLogger(tag: "assets", provider: provider)
    static let authentication = WireLogger(tag: "authentication", provider: provider)
    static let backgroundActivity = WireLogger(tag: "background-activity", provider: provider)
    static let badgeCount = WireLogger(tag: "badge-count", provider: provider)
    static let backend = WireLogger(tag: "backend", provider: provider)
    static let calling = WireLogger(tag: "calling", provider: provider)
    static let conversation = WireLogger(tag: "conversation", provider: provider)
    static let coreCrypto = WireLogger(tag: "core-crypto", provider: provider)
    static let e2ei = WireLogger(tag: "end-to-end-identity", provider: provider)
    static let ear = WireLogger(tag: "encryption-at-rest", provider: provider)
    static let environment = WireLogger(tag: "environment", provider: provider)
    static let featureConfigs = WireLogger(tag: "feature-configurations", provider: provider)
    static let keychain = WireLogger(tag: "keychain", provider: provider)
    static let localStorage = WireLogger(tag: "local-storage", provider: provider)
    static let mainCoordinator = WireLogger(tag: "main-coordinator", provider: provider)
    static let messaging = WireLogger(tag: "messaging", provider: provider)
    static let mls = WireLogger(tag: "mls", provider: provider)
    static let notifications = WireLogger(tag: "notifications", provider: provider)
    static let performance = WireLogger(tag: "performance", provider: provider)
    static let push = WireLogger(tag: "push", provider: provider)
    static let pushChannel = WireLogger(tag: "push-channel", provider: provider)
    static let proteus = WireLogger(tag: "proteus", provider: provider)
    static let session = WireLogger(tag: "session", provider: provider)
    static let sessionManager = WireLogger(tag: "SessionManager", provider: provider)
    static let shareExtension = WireLogger(tag: "share-extension", provider: provider)
    static let sync = WireLogger(tag: "sync", provider: provider)
    static let system = WireLogger(tag: "system", provider: provider)
    static let timePoint = WireLogger(tag: "timePoint", provider: provider)
    static let ui = WireLogger(tag: "UI", provider: provider)
    static let updateEvent = WireLogger(tag: "update-event", provider: provider)
    static let userClient = WireLogger(tag: "user-client", provider: provider)
    static let network = WireLogger(tag: "network", provider: provider)
    static let eventProcessing = WireLogger(tag: "event-processing", provider: provider)
    static let safeFileContext = WireLogger(tag: "safe-file-context", provider: provider)
    static let messageProcessing = WireLogger(tag: "message-processing", provider: provider)
}
