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

import Foundation
import WireDataModel
import WireSyncEngine

// MARK: - Analytics

final class Analytics: NSObject {
    // MARK: Lifecycle

    required init(optedOut: Bool) {
        self.provider = optedOut ? nil : AnalyticsProviderFactory.shared.analyticsProvider()

        super.init()

        setupObserver()
    }

    // MARK: Internal

    static var shared: Analytics!

    var provider: AnalyticsProvider?

    var selfUser: UserType? {
        get {
            provider?.selfUser
        }

        set {
            if let newValue {
                let idProvider = AnalyticsIdentifierProvider(selfUser: newValue)
                idProvider.setIdentifierIfNeeded()
            }
            provider?.selfUser = newValue

            if let user = newValue, let userSession = ZMUserSession.shared() {
                userObserverToken = UserChangeInfo.add(observer: self, for: user, in: userSession)

            } else {
                userObserverToken = nil
            }
        }
    }

    func tagEvent(
        _ event: String,
        attributes: [String: Any]
    ) {
        guard let attributes = attributes as? [String: NSObject] else { return }

        tagEvent(event, attributes: attributes)
    }

    // MARK: - OTREvents

    func tagCannotDecryptMessage(
        withAttributes userInfo: [String: Any],
        conversation: ZMConversation?
    ) {
        var attributes: [String: Any] = conversation?.attributesForConversation ?? [:]

        attributes.merge(userInfo) { _, new in new }
        tagEvent("e2ee.failed_message_decryption", attributes: attributes)
    }

    // MARK: Private

    private var callingTracker: AnalyticsCallingTracker?
    private var decryptionFailedObserver: AnalyticsDecryptionFailedObserver?
    private var userObserverToken: Any?

    private func setupObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(userSessionDidBecomeAvailable(_:)),
            name: Notification.Name.ZMUserSessionDidBecomeAvailable,
            object: nil
        )
    }

    @objc
    private func userSessionDidBecomeAvailable(_: Notification?) {
        callingTracker = AnalyticsCallingTracker(analytics: self)
        selfUser = SelfUser.provider?.providedSelfUser

        decryptionFailedObserver = AnalyticsDecryptionFailedObserver(analytics: self)
    }
}

// MARK: AnalyticsType

extension Analytics: AnalyticsType {
    func setPersistedAttributes(_ attributes: [String: NSObject]?, for event: String) {
        // no-op
    }

    func persistedAttributes(for event: String) -> [String: NSObject]? {
        // no-op
        nil
    }

    /// Record an event with no attributes
    func tagEvent(_ event: String) {
        provider?.tagEvent(event, attributes: [:])
    }

    /// Record an event with optional attributes.
    /// - Parameters:
    ///   - event: event to tag
    ///   - attributes: attributes of the event
    func tagEvent(_ event: String, attributes: [String: NSObject]) {
        provider?.tagEvent(event, attributes: attributes)
    }
}

// MARK: UserObserving

extension Analytics: UserObserving {
    func userDidChange(_ changeInfo: UserChangeInfo) {
        guard
            changeInfo.user.isSelfUser,
            changeInfo.analyticsIdentifierChanged
        else {
            return
        }

        selfUser = nil
        selfUser = changeInfo.user
    }
}
