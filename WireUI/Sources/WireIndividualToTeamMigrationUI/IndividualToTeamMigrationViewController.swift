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

import SwiftUI
import WireDesign
import WireDomainPackage
import WireFoundation
import WireReusableUIComponents

public class IndividualToTeamMigrationViewController: UIViewController {
    public enum Action: Sendable {
        case cancel
        case toLearnMoreAboutPlans
        case completionDismiss
        case completionGoToConversations
        case completionGoToTeamManagement
    }

    enum Step: Sendable {
        case teamPlanSelection(features: [TeamPlanFeature])
        case teamName
        case confirmation(teamName: String, termsOfUseURL: String, privacyPolicyURL: String)
        case completion(profileName: String, teamName: String)

        var title: String {
            switch self {
            case .teamPlanSelection, .teamName, .confirmation:
                .localized(key: titleStringKey, bundle: .module)
            case let .completion(profileName, _):
                .formated(key: titleStringKey, bundle: .module, profileName)
            }
        }

        var closeButtonAccessibilityLabel: String {
            switch self {
            case .teamPlanSelection:
                .localizedAccessibilityLabel(
                    key: "individualToTeam.planSelection.closeButton.accessibilityLabel",
                    bundle: .module
                )
            case .teamName:
                .localizedAccessibilityLabel(
                    key: "individualToTeam.teamName.closeButton.accessibilityLabel",
                    bundle: .module
                )
            case .confirmation:
                .localizedAccessibilityLabel(
                    key: "individualToTeam.confirmation.closeButton.accessibilityLabel",
                    bundle: .module
                )
            case .completion:
                .localizedAccessibilityLabel(
                    key: "individualToTeam.completion.closeButton.accessibilityLabel",
                    bundle: .module
                )
            }
        }

        private var titleStringKey: String.LocalizationValue {
            switch self {
            case .teamPlanSelection:
                "individualToTeam.planSelection.title"
            case .teamName:
                "individualToTeam.teamName.title"
            case .confirmation:
                "individualToTeam.confirmation.title"
            case .completion:
                "individualToTeam.completion.title"
            }
        }
    }

    enum Transition: Sendable {
        case toCancellationAlert
        case toPlans
        case toLearnMoreAboutPlans
        case toTeamName
        case toConfirmation(teamName: String)
        case toTeamCreation(teamName: String)
        case toError(error: any Error)
        case toCompletion(teamName: String)
        case toCompletionDismiss
        case toConversations
        case toTeamManagement
    }

    let actionCallback: @Sendable (Action) -> Void
    lazy var blockingActivityIndicator: BlockingActivityIndicator = .init(
        view: view,
        accessibilityAnnouncement: .localizedAccessibilityLabel(key: "individualToTeam.loading", bundle: .module)
    )
    let childController: UINavigationController
    private var currentStep: Step?
    let features: [TeamPlanFeature]
    let termsOfUseURL: String
    let privacyPolicyURL: String
    let useCase: any IndividualToTeamMigrationUseCaseProtocol
    let userProfileName: String
    private var analyticsFlowCompletionAction: PostAccountMigrationAction?
    private let analyticsEventTracker: (any AccountMigrationAnalyticsTrackerProtocol)?

    public init(
        features: [TeamPlanFeature],
        privacyPolicyURL: String,
        termsOfUseURL: String,
        useCase: any IndividualToTeamMigrationUseCaseProtocol,
        userProfileName: String,
        analyticsEventTracker: (any AccountMigrationAnalyticsTrackerProtocol)?,
        actionCallback: @escaping @Sendable (Action) -> Void
    ) {
        self.analyticsEventTracker = analyticsEventTracker
        self.actionCallback = actionCallback
        self.childController = UINavigationController()
        self.features = features
        self.privacyPolicyURL = privacyPolicyURL
        self.termsOfUseURL = termsOfUseURL
        self.useCase = useCase
        self.userProfileName = userProfileName
        super.init(nibName: nil, bundle: nil)
        isModalInPresentation = true
    }

    public convenience init(
        privacyPolicyURL: String,
        termsOfUseURL: String,
        useCase: any IndividualToTeamMigrationUseCaseProtocol,
        userProfileName: String,
        analyticsEventTracker: (any AccountMigrationAnalyticsTrackerProtocol)?,
        actionCallback: @escaping @Sendable (Action) -> Void
    ) {
        self.init(
            features: .features,
            privacyPolicyURL: privacyPolicyURL,
            termsOfUseURL: termsOfUseURL,
            useCase: useCase,
            userProfileName: userProfileName,
            analyticsEventTracker: analyticsEventTracker,
            actionCallback: actionCallback
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        addChild(childController)
        view.addSubview(childController.view)
        childController.didMove(toParent: self)
        childController.navigationBar.tintColor = ColorTheme.Backgrounds.onBackground
        transition(to: .toPlans)
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isBeingDismissed {
            analyticsEventTracker?.trackMigrationCompleted(postAction: analyticsFlowCompletionAction)
        }
    }

    @MainActor
    func transition(to transition: Transition) {
        switch transition {
        case .toCancellationAlert:
            let alert = cancellationSheetFactory(
                onLeave: { [weak self] in
                    self?.analyticsEventTracker?.trackMigrationCancelAttempt(choice: .confirm)
                    self?.actionCallback(.cancel)
                }, onContinue: { [weak self] in
                    self?.analyticsEventTracker?.trackMigrationCancelAttempt(choice: .backOut)
                }
            )
            childController.present(alert, animated: true)
            isModalInPresentation = true
        case .toPlans:
            let step = Step.teamPlanSelection(features: features)
            currentStep = step
            let vc = hostedView(
                for: step,
                stepIndex: childController.viewControllers.count + 1,
                stepCount: 4,
                onTransition: { @MainActor [weak self] in self?.transition(to: $0) }
            )
            childController.pushViewController(vc, animated: false) { [analyticsEventTracker] in
                analyticsEventTracker?.trackMigrationReachedDisclaimerStep()
            }
            isModalInPresentation = true
        case .toLearnMoreAboutPlans:
            actionCallback(.toLearnMoreAboutPlans)
        case .toTeamName:
            let step = Step.teamName
            currentStep = step
            let vc = hostedView(
                for: step,
                stepIndex: childController.viewControllers.count + 1,
                stepCount: 4,
                onTransition: { @MainActor [weak self] in self?.transition(to: $0) }
            )
            childController.pushViewController(vc, animated: true) { [analyticsEventTracker] in
                analyticsEventTracker?.trackMigrationReachedTeamNameStep()
            }
            isModalInPresentation = true
        case let .toConfirmation(teamName):
            let step = Step.confirmation(
                teamName: teamName,
                termsOfUseURL: termsOfUseURL,
                privacyPolicyURL: privacyPolicyURL
            )
            currentStep = step
            let vc = hostedView(
                for: step,
                stepIndex: childController.viewControllers.count + 1,
                stepCount: 4,
                onTransition: { @MainActor [weak self] in self?.transition(to: $0) }
            )
            childController.pushViewController(vc, animated: true) { [analyticsEventTracker] in
                analyticsEventTracker?.trackMigrationReachedConfirmationStep()
            }
            isModalInPresentation = true
        case let .toTeamCreation(teamName: teamName):
            createTeam(named: teamName)
        case let .toError(error as IndividualToTeamMigrationError):
            displayError(error)
        case let .toError(error):
            displayGenericError(error)
        case let .toCompletion(teamName):
            let step = Step.completion(profileName: userProfileName, teamName: teamName)
            currentStep = step
            let vc = hostedView(
                for: step,
                stepIndex: 4,
                stepCount: 4,
                onTransition: { @MainActor [weak self] in self?.transition(to: $0) }
            )
            childController.setViewControllers([vc], animated: true)
            isModalInPresentation = true
        case .toCompletionDismiss:
            analyticsFlowCompletionAction = nil
            actionCallback(.completionDismiss)
        case .toConversations:
            analyticsFlowCompletionAction = .returnToApp
            actionCallback(.completionGoToConversations)
        case .toTeamManagement:
            analyticsFlowCompletionAction = .openTeamManagement
            actionCallback(.completionGoToTeamManagement)
        }
    }

    private func createTeam(named teamName: String) {
        blockingActivityIndicator.start()
        Task {
            do {
                let migrationResult = try await self.useCase.invoke(teamName: teamName)
                transition(to: .toCompletion(teamName: migrationResult.teamName))
                blockingActivityIndicator.stop()
            } catch {
                transition(to: .toError(error: error))
                blockingActivityIndicator.stop()
            }
        }
    }

    private func displayError(_ error: IndividualToTeamMigrationError) {
        switch error {
        case .userAlreadyInTeam:
            displayError(
                title: .localized(key: "individualToTeam.error.alreadyPartOfTeam.title", bundle: .module),
                body: .localized(key: "individualToTeam.error.alreadyPartOfTeam.body", bundle: .module),
                action: .localized(key: "individualToTeam.error.alreadyPartOfTeam.action", bundle: .module)
            )
        case let .generic(error):
            displayGenericError(error)
        }
    }

    private func displayGenericError(_ error: some Error) {
        displayError(
            title: .localized(key: "individualToTeam.error.generic.title", bundle: .module),
            body: .localized(key: "individualToTeam.error.generic.body", bundle: .module),
            action: .localized(key: "individualToTeam.error.generic.action", bundle: .module)
        )
    }

    private func displayError(title: String, body: String, action: String) {
        let alert = errorAlertFactory(title: title, body: body, action: action)
        present(alert, animated: true)
    }
}

extension IndividualToTeamMigrationViewController: UIAdaptivePresentationControllerDelegate {

    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        guard let currentStep else { return assertionFailure("unexpected state") }

        switch currentStep {
        case .teamPlanSelection:
            analyticsEventTracker?.trackMigrationDroppedAtDisclaimerStep()
        case .teamName:
            analyticsEventTracker?.trackMigrationDroppedAtTeamNameStep()
        case .confirmation:
            analyticsEventTracker?.trackMigrationDroppedAtConfirmationStep()
        case .completion:
            // the flow-completed event will handle this case
            break
        }
    }
}

@MainActor
private func hostedView(
    for step: IndividualToTeamMigrationViewController.Step,
    stepIndex: Int,
    stepCount: Int,
    onTransition transitionCallback: @escaping @MainActor @Sendable (
        IndividualToTeamMigrationViewController
            .Transition
    ) -> Void
) -> UIViewController {
    let vc = UIHostingController(
        rootView:
        PageContainer(
            content: { viewFor(
                step: step,
                stepIndex: stepIndex,
                stepCount: stepCount,
                onTransition: transitionCallback
            ) },
            step: stepIndex,
            stepCount: stepCount,
            stepTitle: step.title
        )
        .environment(\.wireTextStyleMapping, WireTextStyleMapping())
    )
    vc.title = step.title
    if case .completion = step {
        vc.navigationItem.rightBarButtonItem = nil
    } else {
        vc.navigationItem.rightBarButtonItem = UIBarButtonItem.closeButton(
            action: UIAction { _ in
                switch step {
                case .teamPlanSelection, .teamName, .confirmation:
                    transitionCallback(.toCancellationAlert)
                case .completion:
                    transitionCallback(.toCompletionDismiss)
                }
            },
            accessibilityLabel: step.closeButtonAccessibilityLabel
        )
    }
    // Hide navigation bar title
    vc.navigationItem.titleView = UIView()
    vc.navigationItem.rightBarButtonItem?.tintColor = ColorTheme.Backgrounds.onBackground
    vc.navigationItem.leftBarButtonItem?.tintColor = ColorTheme.Backgrounds.onBackground
    return vc
}

@MainActor
@ViewBuilder
private func viewFor(
    step: IndividualToTeamMigrationViewController.Step,
    stepIndex: Int,
    stepCount: Int,
    onTransition transitionCallback: @escaping @MainActor @Sendable (
        IndividualToTeamMigrationViewController
            .Transition
    ) -> Void
) -> some View {
    switch step {
    case let .teamPlanSelection(features):
        TeamPlanSelectionView(features: features) { action in
            switch action {
            case .goToPlans:
                transitionCallback(.toLearnMoreAboutPlans)
            case .continue:
                transitionCallback(.toTeamName)
            }
        }
    case .teamName:
        TeamNameView { action in
            switch action {
            case let .continue(teamName):
                transitionCallback(.toConfirmation(teamName: teamName))
            }
        }
    case let .confirmation(teamName, termsOfUseURL, privacyPolicyURL):
        ConfirmationView(
            termsOfUseURL: termsOfUseURL,
            privacyPolicyURL: privacyPolicyURL
        ) { action in
            switch action {
            case .continue:
                transitionCallback(.toTeamCreation(teamName: teamName))
            }
        }
    case let .completion(profileName, teamName):
        CompletionView(profileName: profileName, teamName: teamName) { action in
            switch action {
            case .goBack:
                transitionCallback(.toConversations)
            case .goToTeamManagement:
                transitionCallback(.toTeamManagement)
            }
        }
    }
}

#Preview {
    featurePreview()
}
