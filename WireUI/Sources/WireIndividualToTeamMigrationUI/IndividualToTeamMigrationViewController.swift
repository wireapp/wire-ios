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

import SwiftUI
import UIKit
import WireDesign
import WireDomainAPI

public class IndividualToTeamMigrationViewController: UIViewController {
    enum Step: Sendable {
        case teamPlanSelection(features: [TeamPlanFeature])
        case teamName
        case confirmation
        case completion(profileName: String, teamName: String)

        var title: String {
            switch self {
            case .teamPlanSelection, .teamName, .confirmation:
                return .localized(key: titleStringKey, bundle: .module)
            case .completion(let profileName, _):
                return .formated(key: titleStringKey, bundle: .module, profileName)
            }
        }

        var closeButtonAccessibilityLabel: String {
            switch self {
            case .teamPlanSelection:
                return .localizedAccessibilityLabel(key: "individualToTeam.planSelection.closeButton.accessibilityLabel", bundle: .module)
            case .teamName:
                return .localizedAccessibilityLabel(key: "individualToTeam.teamName.closeButton.accessibilityLabel", bundle: .module)
            case .confirmation:
                return .localizedAccessibilityLabel(key: "individualToTeam.confirmation.closeButton.accessibilityLabel", bundle: .module)
            case .completion:
                return .localizedAccessibilityLabel(key: "individualToTeam.completion.closeButton.accessibilityLabel", bundle: .module)
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
        case dismissCancellationAlert
        case toPlans
        case toTeamName
        case toConfirmation
        case toCompletion
        case toApp
        case toTeamManagement
    }

    let childController: UINavigationController
    var currentStep: Step
    let features: [TeamPlanFeature]
    let useCase: any IndividualToTeamMigrationUseCase

    public init(features: [TeamPlanFeature], useCase: any IndividualToTeamMigrationUseCase) {
        self.currentStep = .teamPlanSelection(features: features)
        self.childController = UINavigationController()
        self.features = features
        self.useCase = useCase
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        addChild(childController)
        view.addSubview(childController.view)
        childController.didMove(toParent: self)
        childController.navigationBar.tintColor = .darkText
        transition(to: .toPlans)
    }

    @MainActor
    func transition(to transition: Transition) {
        switch transition {
        case .toCancellationAlert:
            let alert = cancellationSheetFactory(
                onLeave: { [weak self] in
                    self?.transition(to: .toApp)
                }, onContinue: { [weak self] in
                    self?.transition(to: .dismissCancellationAlert)
                })
            childController.present(alert, animated: true)
        case .dismissCancellationAlert:
            childController.dismiss(animated: true)
        case .toPlans:
            let vc = hostedView(
                for: .teamPlanSelection(features: features),
                stepIndex: (childController.viewControllers.count + 1),
                stepCount: 4,
                onTransition: { @MainActor [weak self] in self?.transition(to: $0) }
            )
            childController.pushViewController(vc, animated: false)
        case .toTeamName:
            let vc = hostedView(
                for: .teamName,
                stepIndex: (childController.viewControllers.count + 1),
                stepCount: 4,
                onTransition: { @MainActor [weak self] in self?.transition(to: $0) }
            )
            childController.pushViewController(vc, animated: true)
        case .toConfirmation:
            let vc = hostedView(
                for: .confirmation,
                stepIndex: (childController.viewControllers.count + 1),
                stepCount: 4,
                onTransition: { @MainActor [weak self] in self?.transition(to: $0) }
            )
            childController.pushViewController(vc, animated: true)
        case .toCompletion:
            let vc = hostedView(
                for: .completion(profileName: "Profile Name", teamName: "Some Team"),
                stepIndex: (childController.viewControllers.count + 1),
                stepCount: 4,
                onTransition: { @MainActor [weak self] in self?.transition(to: $0) }
            )
            childController.pushViewController(vc, animated: true)
        case .toApp:
            break
        case .toTeamManagement:
            break
        }
    }
}

@MainActor
private func hostedView(
    for step: IndividualToTeamMigrationViewController.Step,
    stepIndex: Int,
    stepCount: Int,
    onTransition transitionCallback: @escaping @MainActor @Sendable (IndividualToTeamMigrationViewController.Transition) -> Void
) -> UIViewController {
    let vc = UIHostingController(rootView:
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
    )
    vc.title = step.title
    vc.navigationItem.rightBarButtonItem = UIBarButtonItem.closeButton(
        action: UIAction { _ in
            transitionCallback(.toCancellationAlert)
        },
        accessibilityLabel: step.closeButtonAccessibilityLabel
    )
    // Hide navigation bar title
    vc.navigationItem.titleView = UIView()
    vc.navigationItem.rightBarButtonItem?.tintColor = ColorTheme.Backgrounds.onBackground
    return vc
}
@MainActor
@ViewBuilder func viewFor(
    step: IndividualToTeamMigrationViewController.Step,
    stepIndex: Int,
    stepCount: Int,
    onTransition transitionCallback: @escaping @MainActor @Sendable (IndividualToTeamMigrationViewController.Transition) -> Void
) -> some View {
    switch step {
    case .teamPlanSelection(let features):
        TeamPlanSelectionView(features: features) { action in
            switch action {
            case .goToPlans:
                transitionCallback(.toPlans)
            case .continue:
                transitionCallback(.toTeamName)
            }
        }
    case .teamName:
        TeamNameView() { action in
            switch action {
            case .continue(let teamName):
                transitionCallback(.toConfirmation)
            }
        }
    case .confirmation:
        ConfirmationView() { action in
            switch action {
            case .continue:
                transitionCallback(.toCompletion)
            }
        }
    case .completion(let profileName, let teamName):
        CompletionView(profileName: profileName, teamName: teamName) { action in
            switch action {
            case .goBack:
                transitionCallback(.toApp)
            case .goToTeamManagement:
                transitionCallback(.toTeamManagement)
            }
        }
    }
}
