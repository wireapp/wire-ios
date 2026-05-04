//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

import avs
import CallKit
import Foundation
import PushKit
import WireLogging

public protocol VoIPPushManagerDelegate: AnyObject {

    func processPendingCallEvents(accountID: UUID) async

}

public final class VoIPPushManager: NSObject, PKPushRegistryDelegate {

    // MARK: - Properties

    static let pushRegistryQueue = DispatchQueue(
        label: "com.wire.pushRegistryQueue"
    )

    public let callKitManager: CallKitManager

    private let pushTokenService: PushTokenServiceInterface
    private let registry: PKPushRegistry

    public weak var delegate: VoIPPushManagerDelegate?

    private static let logger = WireLogger.calling

    // MARK: - Life cycle

    public init(
        application: ZMApplication,
        pushTokenService: PushTokenServiceInterface
    ) {
        Self.logger.debug("init VoIPPushManager")
        self.pushTokenService = pushTokenService

        self.registry = PKPushRegistry(queue: Self.pushRegistryQueue)
        self.callKitManager = CallKitManager(
            application: application,
            mediaManager: AVSMediaManager.sharedInstance()
        )

        super.init()

        registry.delegate = self
    }

    // MARK: - Methods

    public func registerForVoIPPushes() {
        Self.logger.debug("register for voIP pushes")
        registry.desiredPushTypes = [.voIP]
    }

    public func pushRegistry(
        _ registry: PKPushRegistry,
        didUpdate pushCredentials: PKPushCredentials,
        for type: PKPushType
    ) {
        // do nothing
    }

    public func pushRegistry(
        _ registry: PKPushRegistry,
        didInvalidatePushTokenFor type: PKPushType
    ) {
        // do nothing
    }

    // Don't use the async version, it's broken
    // It doesn't properly get called when waking up the app from the background and ends up crashing
    // See latest comments https://stackoverflow.com/questions/56788314/ios-13-killing-app-because-it-never-posted-an-incoming-call-to-the-system-after
    public func pushRegistry(
        _ registry: PKPushRegistry,
        didReceiveIncomingPushWith payload: PKPushPayload,
        for type: PKPushType,
        completion: @escaping () -> Void
    ) {
        Self.logger.debug("did receive incoming push: \(payload.safeForLoggingDescription)")

        // We're only interested in voIP tokens.
        guard type == .voIP else { return completion() }

        processNSEPush(
            payload: payload.dictionaryPayload,
            completion: completion
        )
    }

    private func processNSEPush(
        payload: [AnyHashable: Any],
        completion: @escaping () -> Void
    ) {
        guard
            let accountIDString = payload["accountID"] as? String,
            let accountID = UUID(uuidString: accountIDString),
            let conversationIDString = payload["conversationID"] as? String,
            let conversationID = UUID(uuidString: conversationIDString),
            let shouldRing = payload["shouldRing"] as? Bool,
            let callerName = payload["callerName"] as? String,
            let hasVideo = payload["hasVideo"] as? Bool
        else {
            Self.logger.critical("error: processing NSE push: invalid payload - \(payload)")
            completion()
            return
        }

        let handle = CallHandle(
            accountID: accountID,
            conversationID: conversationID
        )

        // Report the call immediately to fulfill API obligations, otherwise the app will be killed.
        // See https://developer.apple.com/documentation/callkit/sending_end-to-end_encrypted_voip_calls
        if shouldRing {
            Self.logger.info("will report new incoming call")
            callKitManager.reportIncomingCallPreemptively(
                handle: handle,
                callerName: callerName,
                hasVideo: hasVideo
            )
        } else {
            Self.logger.info("will report call ended")
            callKitManager.reportCallEndedPreemptively(
                handle: handle,
                reason: .unanswered
            )
        }

        Task {
            Self.logger.debug("processPendingCallEvents")
            await delegate?.processPendingCallEvents(accountID: accountID)
            // Note that here we don't guarantee the sync was finished, only that it was triggered
            completion()
        }
    }
}
