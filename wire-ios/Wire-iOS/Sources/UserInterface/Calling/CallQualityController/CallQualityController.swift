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

import UIKit
import WireCommonComponents
import WireSyncEngine
import WireAnalytics
/**
 * Observes call state to prompt the user for call quality feedback when appropriate.
 */

class CallQualityController: NSObject {

    weak var router: CallQualityRouterProtocol?

    fileprivate var answeredCalls: [UUID: Date] = [:]
    fileprivate var token: Any?

    private let rootViewController: UIViewController
    private let analyticsEventTracker: AnalyticsEventTracker

    init(rootViewController: UIViewController, analyticsEventTracker: AnalyticsEventTracker) {
        self.rootViewController = rootViewController
        self.analyticsEventTracker = analyticsEventTracker
        super.init()
        
        if let userSession = ZMUserSession.shared() {
            token = WireCallCenterV3.addCallStateObserver(observer: self, userSession: userSession)
        }
    }

    // MARK: - Configuration

    /// Whether we use a maxmimum budget for call surveying per user.
    var usesCallSurveyBudget: Bool = true

    /// The range of scores where we consider the call quality is not satisfying.
    let callQualityRejectionRange = 1 ... 2

    /// The minimum duration for calls to trigger a survey.
    let miminumSignificantCallDuration: TimeInterval = 0

    /**
     * Whether the call quality survey can be presented.
     *
     * We only present the call quality survey for internal users and if the application is in the foreground.
     */

    var canPresentCallQualitySurvey: Bool {
        #if DISABLE_CALL_QUALITY_SURVEY
        return false
        #else
        return !AutomationHelper.sharedHelper.disableCallQualitySurvey
            && AppDelegate.shared.launchType != .unknown
        #endif
    }

    // MARK: - Events

    /**
     * Handles the start of the call in the specified conversation. Call this method when the call
     * is established.
     * - parameter conversation: The conversation where the call is ongoing.
     */

    private func handleCallStart(in conversation: ZMConversation) {
        answeredCalls[conversation.remoteIdentifier!] = Date()
    }

    /**
     * Handles the end of a call in the specified conversation.
     * - parameter conversation: The conversation where the call ended.
     * - parameter reason: The reason why the call ended.
     * - parameter eventDate: The date when the call ended.
     */

    private func handleCallCompletion(in conversation: ZMConversation, reason: CallClosedReason, eventDate: Date) {
        // Check for the call start date (do not show feedback for unanswered calls)
        guard let callStartDate = answeredCalls[conversation.remoteIdentifier!] else {
            return
        }

        switch reason {
        case .normal, .stillOngoing:
            handleCallSuccess(callStartDate: callStartDate, callEndDate: eventDate)
        case .answeredElsewhere:
            break
        case .securityDegraded:
            // handled in CallController, ignore
            break
        default:
            handleCallFailure(presentingViewController: rootViewController)
        }

        answeredCalls[conversation.remoteIdentifier!] = nil
    }

    /// Presents the call quality survey after a successful call.
    private func handleCallSuccess(callStartDate: Date, callEndDate: Date) {
        let callDuration = callEndDate.timeIntervalSince(callStartDate)

        guard callDuration >= miminumSignificantCallDuration else {
            analyticsEventTracker.trackEvent(.callQualitySurvey(.notDisplayed(reason: .callTooShort, duration: Int(callDuration)))
            return
        }

        guard self.canRequestSurvey(at: callEndDate) else {
            analyticsEventTracker.trackEvent(.callQualitySurvey(.notDisplayed(reason: .muted, duration: Int(callDuration)))
            return
        }

        #if !DISABLE_CALL_QUALITY_SURVEY
        router?.presentCallQualitySurvey(with: callDuration)
        #endif
    }

    /// Presents the debug log prompt after a call failure.
    private func handleCallFailure(presentingViewController: UIViewController) {
        router?.presentCallFailureDebugAlert(presentingViewController: presentingViewController)
    }

    /// Presents the debug log prompt after a user quality rejection.
    private func handleCallQualityRejection(presentingViewController: UIViewController) {
        router?.presentCallQualityRejection(presentingViewController: presentingViewController)
    }

}

// MARK: - Call State

extension CallQualityController: WireCallCenterCallStateObserver {

    func callCenterDidChange(callState: CallState, conversation: ZMConversation, caller: UserType, timestamp: Date?, previousCallState: CallState?) {
        guard canPresentCallQualitySurvey else { return }
        let eventDate = Date()

        switch callState {
        case .established:
            handleCallStart(in: conversation)
        case .terminating(let terminationReason):
            handleCallCompletion(in: conversation, reason: terminationReason, eventDate: eventDate)
        case .incoming:
            // When call incoming, dismiss CallQuality VC in CallController.presentCall
            break
        default:
            return
        }
    }
}

// MARK: - User Input

extension CallQualityController: CallQualityViewControllerDelegate {

    func callQualityController(_ controller: CallQualityViewController, didSelect score: Int) {
        router?.dismissCallQualitySurvey { [weak self] in
            guard
                self?.callQualityRejectionRange.contains(score) ?? false,
                let presentingViewController = self?.rootViewController
            else { return }

            self?.handleCallQualityRejection(presentingViewController: presentingViewController)
        }

        CallQualityController.updateLastSurveyDate(Date())
        analyticsEventTracker.trackEvent(.callQualitySurvey(.answered(score: score, duration: controller.callDuration)))
    }

    func callQualityControllerDidFinishWithoutScore(_ controller: CallQualityViewController) {
        CallQualityController.updateLastSurveyDate(Date())
        router?.dismissCallQualitySurvey(completion: nil)
    }
}
