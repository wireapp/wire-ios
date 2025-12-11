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

import avs
import CallKit
import Foundation
import Intents
import WireLogging
import WireRequestStrategy

protocol CallKitManagerDelegate: AnyObject {

    /// Look a conversation where a call has or will take place

    func lookupConversation(
        by handle: CallHandle,
        completionHandler: @escaping (Result<ZMConversation, Error>) -> Void
    )

    func lookupConversationAndProcessPendingCallEvents(
        by handle: CallHandle,
        completionHandler: @escaping (Result<ZMConversation, Error>) -> Void
    )

    /// End all active calls in all user sessions

    func endAllCalls()

    /// Called when all calls have ended

    func didEndAllCalls()

}

@objc
public protocol CallKitManagerInterface {

    var isEnabled: Bool { get set }

    func setDelegate(_ delegate: Any)
    func updateConfiguration()
    func continueUserActivity(_ userActivity: NSUserActivity) -> Bool
    func requestMuteCall(in conversation: ZMConversation, muted: Bool)
    func requestJoinCall(in conversation: ZMConversation, video: Bool)
    func requestEndCall(in conversation: ZMConversation, completion: (() -> Void)?)

}

@objc
public class CallKitManager: NSObject, CallKitManagerInterface {

    // MARK: - Properties

    public var isEnabled: Bool {
        didSet {
            VoIPPushHelper.isCallKitAvailable = isEnabled
        }
    }

    private let application: ZMApplication
    private let delegateQueue = DispatchQueue(label: "CallkitProviderDelegateQueue")
    private let provider: CXProvider
    private let callController: CXCallController
    private weak var mediaManager: MediaManagerType?

    weak var delegate: CallKitManagerDelegate?

    private var callStateObserverToken: Any?
    private var missedCallObserverToken: Any?

    let callRegister = CallKitCallRegister()
    private var connectedCallConversation: ZMConversation?

    private let logger = WireLogger.callkit

    // MARK: - Life cycle

    public convenience init(
        application: ZMApplication,
        mediaManager: MediaManagerType
    ) {
        self.init(
            application: application,
            mediaManager: mediaManager,
            delegate: nil
        )
    }

    convenience init(
        application: ZMApplication,
        mediaManager: MediaManagerType,
        delegate: CallKitManagerDelegate?
    ) {
        self.init(
            application: application,
            provider: CXProvider(configuration: CallKitManager.providerConfiguration),
            callController: CXCallController(queue: DispatchQueue.main),
            mediaManager: mediaManager,
            delegate: delegate
        )
    }

    init(
        isEnabled: Bool = false,
        application: ZMApplication,
        provider: CXProvider,
        callController: CXCallController,
        mediaManager: MediaManagerType?,
        delegate: CallKitManagerDelegate? = nil
    ) {
        self.isEnabled = isEnabled
        self.application = application
        self.provider = provider
        self.callController = callController
        self.mediaManager = mediaManager
        self.delegate = delegate

        super.init()

        provider.setDelegate(self, queue: delegateQueue)

        self.callStateObserverToken = WireCallCenterV3.addGlobalCallStateObserver(observer: self)
        self.missedCallObserverToken = WireCallCenterV3.addGlobalMissedCallObserver(observer: self)
    }

    deinit {
        provider.invalidate()
    }

    // MARK: - Delegate

    public func setDelegate(_ delegate: Any) {
        // The type is any as a way to make the CallKitManagerInterface exposed to
        // objective c.
        if let delegate = delegate as? CallKitManagerDelegate {
            self.delegate = delegate
        }
    }

    // MARK: - Configuration

    public func updateConfiguration() {
        logger.info("update configuration")
        provider.configuration = CallKitManager.providerConfiguration
    }

    static var providerConfiguration: CXProviderConfiguration {
        let configuration = CXProviderConfiguration()
        configuration.supportsVideo = true
        configuration.maximumCallGroups = 1
        configuration.maximumCallsPerCallGroup = 1
        configuration.supportedHandleTypes = [.generic]
        configuration.ringtoneSound = NotificationSound.call.name

        if let image = UIImage(named: "wire-logo-letter") {
            configuration.iconTemplateImageData = image.pngData()
        }

        return configuration
    }

    // MARK: - Actions

    private func actionsToEndAllOngoingCalls(excepting handle: CallHandle) -> [CXAction] {
        callRegister.allCalls
            .lazy
            .filter { $0.handle != handle }
            .map { CXEndCallAction(call: $0.id) }
    }

    // MARK: - Intents

    func findConversationAssociated(
        with contacts: [INPerson],
        completion: @escaping (ZMConversation) -> Void
    ) {
        guard
            contacts.count == 1,
            let contact = contacts.first,
            let customIdentifier = contact.personHandle?.value,
            let callHandle = CallHandle(encodedString: customIdentifier)
        else {
            return
        }

        delegate?.lookupConversation(by: callHandle) { result in
            guard case let .success(conversation) = result else { return }
            completion(conversation)
        }
    }

    public func continueUserActivity(_ userActivity: NSUserActivity) -> Bool {
        logger.info("continue user activity")
        guard let interaction = userActivity.interaction else { return false }

        let intent = interaction.intent
        var contacts: [INPerson]?
        var video = false

        // swiftlint:disable:next todo_requires_jira_link
        // TODO: handle INStartVideoCallIntent for when CallKit video is toggled.
        if let startCallIntent = intent as? INStartCallIntent {
            contacts = startCallIntent.contacts
            video = startCallIntent.callCapability == .videoCall
        }

        if let contacts {
            findConversationAssociated(with: contacts) { [weak self] conversation in
                self?.requestStartCall(in: conversation, video: video)
            }

            return true

        } else {
            return false
        }
    }

    // MARK: - Requesting actions

    public func requestMuteCall(
        in conversation: ZMConversation,
        muted: Bool
    ) {
        logger.info("request mute call", attributes: .safePublic)

        guard let call = callRegister.lookupCall(by: conversation) else {
            logger.warn("fail: request mute call: call doesn't not exist", attributes: .safePublic)
            return
        }

        let action = CXSetMutedCallAction(
            call: call.id,
            muted: muted
        )

        callController.request(CXTransaction(action: action)) { [weak self] error in
            if let error {
                self?.logger.error("fail: request mute call: \(error)", attributes: .safePublic)
            }
        }
    }

    public func requestJoinCall(
        in conversation: ZMConversation,
        video: Bool
    ) {
        logger.info("request join call")

        if existsIncomingCall(in: conversation) {
            requestAnswerCall(in: conversation, video: video)
        } else {
            requestStartCall(in: conversation, video: video)
        }
    }

    private func existsIncomingCall(in conversation: ZMConversation) -> Bool {
        guard
            let call = callRegister.lookupCall(by: conversation),
            let existingCall = callController.existingCall(for: call)
        else {
            return false
        }

        return !existingCall.isOutgoing
    }

    func requestStartCall(
        in conversation: ZMConversation,
        video: Bool
    ) {
        logger.info("request start call", attributes: .safePublic)

        guard
            let context = conversation.managedObjectContext,
            let handle = conversation.callHandle
        else {
            logger.warn("fail: request start call: context or handle missing", attributes: .safePublic)
            return
        }

        // swiftlint:disable:next todo_requires_jira_link
        // TODO: do we need to check there doesn't already exist a call?
        let call = callRegister.registerNewCall(with: handle)

        let action = CXStartCallAction(call: call.id, handle: handle.cxHandle)
        action.isVideo = video
        action.contactIdentifier = conversation.localizedCallerName(with: ZMUser.selfUser(in: context))

        let endCallActions = actionsToEndAllOngoingCalls(excepting: handle)
        let transaction = CXTransaction(actions: endCallActions + [action])

        callController.request(transaction) { [weak self] error in
            if let error = error as? CXErrorCodeRequestTransactionError, error.code == .callUUIDAlreadyExists {
                self?.logger.info("request start call: call already exists, answering...", attributes: .safePublic)
                self?.requestAnswerCall(in: conversation, video: video)
            } else if let error {
                self?.logger.error("fail: request start call: \(error)", attributes: .safePublic)
            }
        }
    }

    func requestAnswerCall(in conversation: ZMConversation, video: Bool) {
        logger.info("request answer call", attributes: .safePublic)

        guard let call = callRegister.lookupCall(by: conversation) else {
            logger.warn("fail: request answer call: call doesn't exist")
            return
        }

        let action = CXAnswerCallAction(call: call.id)
        let endPreviousActions = actionsToEndAllOngoingCalls(excepting: call.handle)
        let transaction = CXTransaction(actions: endPreviousActions + [action])

        callController.request(transaction) { [weak self] error in
            if let error {
                self?.logger.error("fail: request answer call: \(error)", attributes: .safePublic)
            }
        }
    }

    public func requestEndCall(
        in conversation: ZMConversation,
        completion: (() -> Void)? = nil
    ) {
        logger.info("request end call", attributes: .safePublic)

        guard let call = callRegister.lookupCall(by: conversation) else {
            logger.warn("fail: request end call: call doesn't exist", attributes: .safePublic)
            return
        }

        let action = CXEndCallAction(call: call.id)
        let transaction = CXTransaction(action: action)

        callController.request(transaction) { [weak self] error in
            if let error {
                self?.logger.error("fail: request end call: \(error)", attributes: .safePublic)
                conversation.voiceChannel?.leave()
            }

            completion?()
        }
    }

    // MARK: - Reporting calls

    func reportIncomingCallPreemptively(
        handle: CallHandle,
        callerName: String,
        hasVideo: Bool
    ) {
        logger.info("report incoming call preemptively")

        guard !callRegister.callExists(for: handle) else {
            logger.critical("fail: report incoming call preemptively: call doesn't exist")
            return
        }

        let call = callRegister.registerNewCall(with: handle)

        let update = CXCallUpdate()
        update.localizedCallerName = callerName
        update.remoteHandle = handle.cxHandle
        update.hasVideo = hasVideo
        update.supportsHolding = false
        update.supportsDTMF = false
        update.supportsGrouping = false
        update.supportsUngrouping = false

        // Don't use the async version, it's broken
        // It doesn't get executed when waking up the app from the background and ends up crashing
        // See latest comments https://stackoverflow.com/questions/56788314/ios-13-killing-app-because-it-never-posted-an-incoming-call-to-the-system-after
        provider.reportNewIncomingCall(
            with: call.id,
            update: update
        ) { [weak self] error in
            if let error {
                self?.logger.error("fail: report incoming call preemptively: \(error)", attributes: .safePublic)
                self?.callRegister.unregisterCall(call)
            }
        }
    }

    func reportCallEndedPreemptively(
        handle: CallHandle,
        reason: CXCallEndedReason
    ) {
        logger.info("report call ended preemptively")

        guard let call = callRegister.lookupCall(by: handle) else {
            logger.critical("fail: report call ended preemptively: call doesn't exist")
            return
        }

        provider.reportCall(
            with: call.id,
            endedAt: nil,
            reason: reason
        )

        callRegister.unregisterCall(call)
    }

    /// Reports an incoming call to CallKit.
    ///
    /// - Parameters:
    ///   - user: The caller.
    ///   - conversation: The conversation in which the call is incoming.
    ///   - hasVideo: Whether the caller has video enabled.

    func reportIncomingCall(
        from user: ZMUser,
        in conversation: ZMConversation,
        hasVideo: Bool
    ) {
        logger.info("report incoming call", attributes: .safePublic)

        guard isEnabled else {
            logger.warn("fail: report incoming call: CallKit not enabled", attributes: .safePublic)
            return
        }

        guard let handle = conversation.callHandle else {
            logger.warn("fail: report incoming call: handle doesn't exist", attributes: .safePublic)
            return
        }

        guard !callRegister.callExists(for: handle)  else {
            logger.warn(
                "fail: report incoming call: call already exists, probably b/c it was reported earlier for a push notification",
                attributes: .safePublic
            )
            return
        }

        let update = CXCallUpdate()
        update.localizedCallerName = conversation.localizedCallerName(with: user)
        update.remoteHandle = handle.cxHandle
        update.hasVideo = hasVideo
        update.supportsHolding = false
        update.supportsDTMF = false
        update.supportsGrouping = false
        update.supportsUngrouping = false

        let call = callRegister.registerNewCall(with: handle)

        logger.info("provider.reportNewIncomingCall", attributes: .safePublic)

        provider.reportNewIncomingCall(
            with: call.id,
            update: update
        ) { [weak self] error in
            if let error {
                self?.logger.error("fail: report incoming call: \(error)", attributes: .safePublic)
                self?.callRegister.unregisterCall(call)
                conversation.voiceChannel?.leave()
            } else {
                self?.logger.info("success: report incoming call", attributes: .safePublic)
                self?.mediaManager?.setupAudioDevice()
            }
        }
    }

    /// Reports to CallKit all calls associated with a conversation as ended.
    ///
    /// - Parameters:
    ///   - conversation: The conversation in which the call(s) ended.
    ///   - timestamp: The date at which the call(s) ended.
    ///   - reason: The reason why the call(s) ended.

    func reportCallEnded(
        in conversation: ZMConversation,
        atTime timestamp: Date?,
        reason: CXCallEndedReason
    ) {
        logger.info("report call ended")

        guard isEnabled else {
            logger.warn("fail: report incoming call: CallKit not enabled")
            return
        }

        let associatedCalls = callRegister.allCalls.filter {
            $0.handle == conversation.callHandle
        }

        for call in associatedCalls {
            logger.info("terminating call: \(String(describing: call))")
            callRegister.unregisterCall(call)
            logger.info("provider.reportCallEndedAt: \(String(describing: timestamp))", attributes: .safePublic)
            provider.reportCall(with: call.id, endedAt: timestamp?.clampForCallKit() ?? Date(), reason: reason)
        }
    }

}

// MARK: - Provider delegate

extension CallKitManager: CXProviderDelegate {

    public func providerDidBegin(_ provider: CXProvider) {
        logger.info("provider did begin")
    }

    public func providerDidReset(_ provider: CXProvider) {
        logger.info("provider did reset")
        mediaManager?.resetAudioDevice()
        callRegister.reset()
        delegate?.endAllCalls()
    }

    public func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        logger.info("perform start call action", attributes: .safePublic)

        guard let call = callRegister.lookupCall(by: action.callUUID) else {
            logger.warn("fail: perform start call action: call doesn't exist", attributes: .safePublic)
            action.fail()
            return
        }

        guard let delegate else {
            logger.warn("fail: perform start call action: delegate doesn't exist", attributes: .safePublic)
            action.fail()
            return
        }

        delegate.lookupConversation(by: call.handle) { [weak self] result in
            guard let self else {
                action.fail()
                return
            }

            switch result {
            case let .success(conversation):
                call.observer.startObservingChanges(in: conversation)

                call.observer.onAnswered = {
                    provider.reportOutgoingCall(with: action.callUUID, startedConnectingAt: Date())
                }

                call.observer.onEstablished = {
                    provider.reportOutgoingCall(with: action.callUUID, connectedAt: Date())
                }

                mediaManager?.setupAudioDevice()

                if conversation.voiceChannel?.join(video: action.isVideo) == true {
                    logger.info("success: perform start call action", attributes: .safePublic)
                    action.fulfill()
                } else {
                    logger.error("fail: perform start call action: couldn't join call", attributes: .safePublic)
                    action.fail()
                }

                let update = CXCallUpdate()
                update.remoteHandle = call.handle.cxHandle
                update.localizedCallerName = conversation.localizedCallerNameForOutgoingCall()
                provider.reportCall(with: action.callUUID, updated: update)

            case let .failure(error):
                logger.error(
                    "fail: perform start call action: can't fetch conversation: \(error)",
                    attributes: .safePublic
                )
                action.fail()
            }
        }
    }

    public func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        logger.info("perform answer call action", attributes: .safePublic)

        guard let call = callRegister.lookupCall(by: action.callUUID) else {
            logger.warn("fail: perform answer call action: call doesn't exist", attributes: .safePublic)
            action.fail()
            return
        }

        guard let delegate else {
            logger.warn("fail: perform answer call action: delegate doesn't exist", attributes: .safePublic)
            action.fail()
            return
        }

        delegate.lookupConversationAndProcessPendingCallEvents(by: call.handle) { [weak self] result in
            guard let self else {
                action.fail()
                return
            }

            switch result {
            case let .success(conversation):
                call.observer.startObservingChanges(in: conversation)

                call.observer.onEstablished = { [weak self] in
                    self?.logger.info("success: perform answer call action", attributes: .safePublic)

                    // Users join conferences in a muted state, so we want to make sure
                    // that the CallKit mute state is in sync with the voice channel mute state.
                    if let voiceChannel = conversation.voiceChannel {
                        self?.requestMuteCall(in: conversation, muted: voiceChannel.muted)
                    }

                    action.fulfill()
                }

                call.observer.onFailedToJoin = {
                    self.logger.error("fail: perform answer call action: failed to join", attributes: .safePublic)
                    action.fail()
                }

                call.observer.onTerminated = { [weak self] reason in
                    self?.reportCallEnded(
                        in: conversation,
                        atTime: nil,
                        reason: reason.CXCallEndedReason
                    )
                }

                logger.info("joining the call...", attributes: .safePublic)
                mediaManager?.setupAudioDevice()

                if conversation.voiceChannel?.join(video: false) != true {
                    logger.error("fail: perform answer call action: couldn't join call", attributes: .safePublic)
                    action.fail()
                }

            case let .failure(error):
                logger.error(
                    "fail: perform answer call action: couldn't fetch conversation: \(error)",
                    attributes: .safePublic
                )
                action.fail()
            }
        }
    }

    public func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        logger.info("perform end call action", attributes: .safePublic)

        guard let call = callRegister.lookupCall(by: action.callUUID) else {
            logger.warn("fail: perform end call action: call doesn't exist", attributes: .safePublic)
            action.fail()
            return
        }

        guard let delegate else {
            logger.warn("fail: perform end call action: delegate doesn't exist", attributes: .safePublic)
            action.fail()
            callRegister.unregisterCall(call)
            return
        }

        delegate.lookupConversationAndProcessPendingCallEvents(by: call.handle) { [weak self] result in
            guard let self else {
                action.fail()
                return
            }

            switch result {
            case let .success(conversation):
                conversation.voiceChannel?.leave()
                action.fulfill()
                callRegister.unregisterCall(call)
                logger.info("success: perform end call action", attributes: .safePublic)

                // Check if all calls have ended
                if callRegister.allCalls.isEmpty {
                    delegate.didEndAllCalls()
                }

            case let .failure(error):
                logger.error(
                    "fail: perform end call action: couldn't fetch conversation: \(error)",
                    attributes: .safePublic
                )
                action.fail()
                callRegister.unregisterCall(call)
            }
        }
    }

    public func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        logger.info("perform CXSetHeldCallAction", attributes: .safePublic)

        guard let call = callRegister.lookupCall(by: action.callUUID) else {
            logger.warn("fail CXSetHeldCallAction because call did not exist", attributes: .safePublic)
            action.fail()
            return
        }

        guard let delegate else {
            logger.warn("fail CXSetHeldCallAction because can't fetch conversation", attributes: .safePublic)
            action.fail()
            return
        }

        delegate.lookupConversation(by: call.handle) { [weak self] result in
            guard let self else {
                action.fail()
                return
            }

            switch result {
            case let .success(conversation):
                conversation.voiceChannel?.muted = action.isOnHold
                action.fulfill()

            case let .failure(error):
                logger.error(
                    "fail CXSetHeldCallAction because can't fetch conversation: \(error)",
                    attributes: .safePublic
                )
                action.fail()
            }
        }
    }

    public func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        logger.info("perform CXSetMutedCallAction", attributes: .safePublic)

        guard let call = callRegister.lookupCall(by: action.callUUID) else {
            logger.warn("fail CXSetMutedCallAction because call did not exist", attributes: .safePublic)
            action.fail()
            return
        }

        guard let delegate else {
            logger.warn("fail CXSetMutedCallAction because can't fetch conversation", attributes: .safePublic)
            action.fail()
            return
        }

        delegate.lookupConversation(by: call.handle) { [weak self] result in
            guard let self else {
                action.fail()
                return
            }

            switch result {
            case let .success(conversation):
                conversation.voiceChannel?.muted = action.isMuted
                action.fulfill()

            case let .failure(error):
                logger.error(
                    "fail CXSetMutedCallAction because can't fetch conversation: \(error)",
                    attributes: .safePublic
                )
                action.fail()
            }
        }
    }

    public func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        logger.info("provider did activate audio session")
        mediaManager?.startAudio()
    }

    public func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        logger.info("provider did deactivate audio session")
        mediaManager?.resetAudioDevice()
    }

}

// MARK: - Callstate observer

extension CallKitManager: WireCallCenterCallStateObserver, WireCallCenterMissedCallObserver {

    public func callCenterDidChange(
        callState: CallState,
        conversation: ZMConversation,
        caller: UserType,
        timestamp: Date?,
        previousCallState: CallState?
    ) {
        logger.info("received new call state: \(callState)")

        switch callState {
        case .incoming(let hasVideo, let shouldRing, degraded: _):
            if shouldRing {
                logger.info("should report an incoming call")

                guard
                    let caller = caller as? ZMUser,
                    conversation.mutedMessageTypesIncludingAvailability == .none,
                    !conversation.needsToBeUpdatedFromBackend
                else {
                    logger.info("will not report incoming call, criteria not met")
                    return
                }

                reportIncomingCall(
                    from: caller,
                    in: conversation,
                    hasVideo: hasVideo
                )

            } else {
                logger.info("will report call ended, reason unanswered")

                reportCallEnded(
                    in: conversation,
                    atTime: timestamp,
                    reason: .unanswered
                )
            }

        case let .terminating(reason):
            logger.info("will report call ended, reason: \(reason)")
            reportCallEnded(
                in: conversation,
                atTime: timestamp,
                reason: reason.CXCallEndedReason
            )

        default:
            break
        }
    }

    public func callCenterMissedCall(
        conversation: ZMConversation,
        caller: UserType,
        timestamp: Date,
        video: Bool
    ) {
        guard isEnabled else { return }

        // Since we missed the call we will not have an assigned callUUID and can just create a random one
        provider.reportCall(
            with: UUID(),
            endedAt: timestamp,
            reason: .unanswered
        )
    }

}

// MARK: - Helpers

private extension Date {

    func clampForCallKit() -> Date {
        let twoWeeksBefore = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()
        return clamp(between: twoWeeksBefore, and: Date())
    }

    func clamp(between fromDate: Date, and toDate: Date) -> Date {
        if timeIntervalSinceReferenceDate < fromDate.timeIntervalSinceReferenceDate {
            fromDate
        } else if timeIntervalSinceReferenceDate > toDate.timeIntervalSinceReferenceDate {
            toDate
        } else {
            self
        }
    }
}

extension ZMConversation {

    var callHandle: CallHandle? {
        guard
            let context = managedObjectContext,
            let userID = ZMUser.selfUser(in: context).remoteIdentifier,
            let conversationID = remoteIdentifier
        else {
            return nil
        }

        return CallHandle(
            accountID: userID,
            conversationID: conversationID
        )
    }

    func localizedCallerNameForOutgoingCall() -> String? {
        guard let managedObjectContext  else { return nil }

        return localizedCallerName(with: ZMUser.selfUser(in: managedObjectContext))
    }

}

extension CXCallAction {

    func conversation(in context: NSManagedObjectContext) -> ZMConversation? {
        ZMConversation.fetch(with: callUUID, in: context)
    }

}

extension CallClosedReason {

    var CXCallEndedReason: CXCallEndedReason {
        switch self {
        case .timeout, .timeoutECONN:
            .unanswered
        case .normal, .canceled:
            .remoteEnded
        case .answeredElsewhere:
            .answeredElsewhere
        case .rejectedElsewhere:
            .declinedElsewhere
        default:
            .failed
        }
    }

}

extension CallKitCallRegister {

    func lookupCall(by conversation: ZMConversation) -> CallKitCall? {
        guard let handle = conversation.callHandle else { return nil }
        return lookupCall(by: handle)
    }

}

private extension CXCallController {

    func existingCall(for callKitCall: CallKitCall) -> CXCall? {
        callObserver.calls.first { $0.uuid == callKitCall.id }
    }

}
