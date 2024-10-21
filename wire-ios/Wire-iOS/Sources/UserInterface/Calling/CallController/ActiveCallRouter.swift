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

enum AlertChoice {
    case cancel, confirm, alreadyPresented, ok
}

// MARK: - ActiveCallRouterProtocol
protocol ActiveCallRouterProtocol: AnyObject {
    func presentActiveCall(for voiceChannel: VoiceChannel, animated: Bool)
    func dismissActiveCall(animated: Bool, completion: Completion?)
    func minimizeCall(animated: Bool, completion: Completion?)
    func showCallTopOverlay(for conversation: ZMConversation)
    func hideCallTopOverlay()
    func presentEndingSecurityDegradedAlert(for reason: CallDegradationReason, completion: @escaping (AlertChoice) -> Void)
    func presentIncomingSecurityDegradedAlert(for reason: CallDegradationReason, completion: @escaping (AlertChoice) -> Void)
    func dismissSecurityDegradedAlertIfNeeded()
    func presentUnsupportedVersionAlert()
}

// MARK: - CallQualityRouterProtocol

// sourcery: AutoMockable
protocol CallQualityRouterProtocol: AnyObject {
    func presentCallQualitySurvey(with callDuration: TimeInterval)
    func dismissCallQualitySurvey(completion: Completion?)
    func presentCallFailureDebugAlert(presentingViewController: UIViewController)
    func presentCallQualityRejection(presentingViewController: UIViewController)
}

typealias PostCallAction = ((@escaping Completion) -> Void)

// MARK: - ActiveCallRouter

final class ActiveCallRouter<TopOverlayPresenter>
where TopOverlayPresenter: TopOverlayPresenting {

    // MARK: - Public Property
    var isActiveCallShown = false {
        didSet {
            if isActiveCallShown {
                isPresentingActiveCall = false
            }
        }
    }

    var isPresentingActiveCall = false

    // MARK: - Private Properties

    private let userSession: UserSession
    private let topOverlayPresenter: TopOverlayPresenter
    private let rootViewController: UIViewController
    private let callController: CallController
    private let callQualityController: CallQualityController
    private var transitioningDelegate: CallQualityAnimator

    private var isCallQualityShown = false
    private var isCallTopOverlayShown = false
    private(set) var scheduledPostCallAction: PostCallAction?
    private(set) weak var presentedDegradedAlert: UIAlertController?

    init(
        rootviewController: UIViewController,
        userSession: UserSession,
        topOverlayPresenter: TopOverlayPresenter
    ) {
        self.rootViewController = rootviewController
        self.userSession = userSession
        self.topOverlayPresenter = topOverlayPresenter

        callController = CallController(userSession: userSession)
        callController.callConversationProvider = ZMUserSession.shared()

        callQualityController = CallQualityController(rootViewController: rootViewController, callQualitySurvey: userSession.makeCallQualitySurveyUseCase())
        transitioningDelegate = CallQualityAnimator()

        callController.router = self
        callQualityController.router = self
    }

    // MARK: - Public Implementation
    func updateActiveCallPresentationState() {
        callController.updateActiveCallPresentationState()
    }
}

// MARK: - ActiveCallRouterProtocol
extension ActiveCallRouter: ActiveCallRouterProtocol {

    // MARK: - ActiveCall
    func presentActiveCall(for voiceChannel: VoiceChannel, animated: Bool) {
        guard
            !isPresentingActiveCall,
            !isActiveCallShown
        else {
            return
        }

        // NOTE: We resign first reponder for the input bar since it will attempt to restore
        // first responder when the call overlay is interactively dismissed but canceled.
        UIResponder.currentFirst?.resignFirstResponder()
        var activeCallViewController: UIViewController!
        let bottomSheetActiveCallViewController = CallingBottomSheetViewController(voiceChannel: voiceChannel, userSession: userSession)
        bottomSheetActiveCallViewController.delegate = callController
        activeCallViewController = bottomSheetActiveCallViewController

        let modalVC = ModalPresentationViewController(viewController: activeCallViewController, enableDismissOnPan: !CallingConfiguration.config.paginationEnabled)

        if rootViewController.presentedViewController != nil {
            dismissPresentedAndPresentActiveCall(modalViewController: modalVC, animated: animated)
        } else {
            presentActiveCall(modalViewController: modalVC, animated: animated)
        }
    }

    func dismissActiveCall(animated: Bool = true, completion: Completion? = nil) {
        guard isActiveCallShown else {
            completion?()
            return
        }
        rootViewController.dismiss(animated: animated) { [weak self] in
            self?.isActiveCallShown = false
            if let action = self?.scheduledPostCallAction {
                action {
                    completion?()
                }
            } else {
                completion?()
            }
            self?.scheduledPostCallAction = nil
        }
    }

    func minimizeCall(animated: Bool = true, completion: Completion? = nil) {
        guard isActiveCallShown else {
            completion?()
            return
        }
        dismissActiveCall(animated: animated, completion: completion)
    }

    // MARK: - CallTopOverlay
    func showCallTopOverlay(for conversation: ZMConversation) {
        guard !isCallTopOverlayShown else { return }
        let callTopOverlayController = CallTopOverlayController(conversation: conversation)
        callTopOverlayController.delegate = self
        topOverlayPresenter.presentTopOverlay(callTopOverlayController, animated: true)
        isCallTopOverlayShown = true
    }

    func hideCallTopOverlay() {
        topOverlayPresenter.dismissTopOverlay(animated: true)
        isCallTopOverlayShown = false
    }

    // MARK: - Alerts

    func presentEndingSecurityDegradedAlert(for reason: CallDegradationReason,
                                            completion: @escaping (AlertChoice) -> Void) {
        guard self.presentedDegradedAlert == nil else {
            completion(.alreadyPresented)
            return
        }

        executeOrSchedulePostCallAction { [weak self] postCallActionCompletion in
            let alert: UIAlertController
            switch reason {
            case .degradedUser(user: let user):
                alert = UIAlertController.makeOutgoingDegradedProteusCall(
                    degradedUser: user?.value,
                    callEnded: true,
                    confirmationBlock: { continueDegradedCall in
                        completion(continueDegradedCall ? .confirm : .cancel)
                        postCallActionCompletion()
                })
            case .invalidCertificate:
                alert = UIAlertController.makeEndingDegradedMLSCall(cancelBlock: {
                    completion(.ok)
                    postCallActionCompletion()
                })
            }

            self?.presentedDegradedAlert = alert

            self?.rootViewController.present(alert, animated: true)
        }
    }

    func presentIncomingSecurityDegradedAlert(for reason: CallDegradationReason,
                                              completion: @escaping (AlertChoice) -> Void) {
        guard self.presentedDegradedAlert == nil else {
            completion(.alreadyPresented)
            return
        }

        executeOrSchedulePostCallAction { [weak self] postCallActionCompletion in
            let alert: UIAlertController
            switch reason {
            case .degradedUser(user: let user):
                alert = UIAlertController.makeIncomingDegradedProteusCall(
                    degradedUser: user?.value,
                    callEnded: false,
                    confirmationBlock: { continueDegradedCall in
                        completion(continueDegradedCall ? .confirm : .cancel)
                        postCallActionCompletion()
                    })
            case .invalidCertificate:
                alert = UIAlertController.makeIncomingDegradedMLSCall(confirmationBlock: { answerDegradedCall in
                    completion(answerDegradedCall ? .confirm : .cancel)
                    postCallActionCompletion()
                })
            }

            self?.presentedDegradedAlert = alert

            self?.rootViewController.present(alert, animated: true)
        }
    }

    func dismissSecurityDegradedAlertIfNeeded() {
        guard let alert = self.presentedDegradedAlert else { return }

        alert.dismissIfNeeded()
        self.presentedDegradedAlert = nil
    }

    func presentUnsupportedVersionAlert() {
        executeOrSchedulePostCallAction { [weak self] completion in
            let alert = UIAlertController.unsupportedVersionAlert
            self?.rootViewController.present(alert, animated: true) {
                completion()
            }
        }
    }

    // MARK: - Private Navigation Helpers

    private func dismissPresentedAndPresentActiveCall(modalViewController: ModalPresentationViewController,
                                                      animated: Bool) {
        rootViewController.presentedViewController?.dismiss(animated: true, completion: { [weak self] in
            self?.presentActiveCall(modalViewController: modalViewController, animated: animated)
        })
    }

    private func presentActiveCall(modalViewController: ModalPresentationViewController, animated: Bool) {
        isPresentingActiveCall = true
        rootViewController.present(modalViewController, animated: animated, completion: { [weak self] in
            self?.isActiveCallShown = true
        })
    }

    // MARK: - Helpers

    func executeOrSchedulePostCallAction(_ action: @escaping PostCallAction) {
        if !isActiveCallShown {
            action({})
        } else {
            scheduledPostCallAction = action
        }
    }
}

// MARK: - CallQualityRouterProtocol
extension ActiveCallRouter: CallQualityRouterProtocol {

    func presentCallQualitySurvey(with callDuration: TimeInterval) {
        let qualityController = buildCallQualitySurvey(with: callDuration)

        executeOrSchedulePostCallAction { [weak self] completion in
            self?.rootViewController.present(qualityController, animated: true, completion: { [weak self] in
                self?.isCallQualityShown = true
                completion()
            })
        }
    }

    func dismissCallQualitySurvey(completion: Completion? = nil) {
        guard isCallQualityShown else { return }
        rootViewController.dismiss(animated: true, completion: { [weak self] in
            self?.isCallQualityShown = false
            completion?()
        })
    }

    func presentCallFailureDebugAlert(presentingViewController: UIViewController) {

        let logsMessage = "The call failed. Sending the debug logs can help us troubleshoot the issue and improve the overall app experience."
        let popoverPresentationConfiguration = PopoverPresentationControllerConfiguration.sourceView(
            sourceView: presentingViewController.view,
            sourceRect: .init(
                origin: presentingViewController.view.safeAreaLayoutGuide.layoutFrame.origin,
                size: .zero
            )
        )
        executeOrSchedulePostCallAction { completion in
            DebugAlert.showSendLogsMessage(
                message: logsMessage,
                presentingViewController: presentingViewController,
                fallbackActivityPopoverConfiguration: popoverPresentationConfiguration
            )
            completion()
        }
    }

    func presentCallQualityRejection(presentingViewController: UIViewController) {

        let logsMessage = "Sending the debug logs can help us improve the quality of calls and the overall app experience."
        let popoverPresentationConfiguration = PopoverPresentationControllerConfiguration.sourceView(
            sourceView: presentingViewController.view,
            sourceRect: .init(
                origin: presentingViewController.view.safeAreaLayoutGuide.layoutFrame.origin,
                size: .zero
            )
        )
        executeOrSchedulePostCallAction { completion in
            DebugAlert.showSendLogsMessage(
                message: logsMessage,
                presentingViewController: presentingViewController,
                fallbackActivityPopoverConfiguration: popoverPresentationConfiguration
            )
            completion()
        }
    }

    private func buildCallQualitySurvey(with callDuration: TimeInterval) -> CallQualityViewController {
        let questionLabelText = L10n.Localizable.Calling.QualitySurvey.question
        let qualityController = CallQualityViewController(questionLabelText: questionLabelText,
                                                          callDuration: callDuration)
        qualityController.delegate = callQualityController

        qualityController.modalPresentationCapturesStatusBarAppearance = true
        qualityController.modalPresentationStyle = .overFullScreen
        qualityController.transitioningDelegate = transitioningDelegate
        return qualityController
    }
}

// MARK: - CallTopOverlayControllerDelegate
extension ActiveCallRouter: CallTopOverlayControllerDelegate {
    func voiceChannelTopOverlayWantsToRestoreCall(voiceChannel: VoiceChannel?) {
        guard let voiceChannel else { return }
        isActiveCallShown = false
        presentActiveCall(for: voiceChannel, animated: true)
    }
}
