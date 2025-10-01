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

import UIKit
import WireCommonComponents
import WireDataModel
import WireDesign
import WireSyncEngine
import WireAccountImageUI
import SwiftUI

//final class MeetingsViewController: UIViewController {
//    weak var accountImageView: AccountImageView?
//    private let segmentedControl: UISegmentedControl
//
//    init() {
//        let groupItems: [String] = ["Upcoming", "Past"]
//        self.segmentedControl = UISegmentedControl(items: groupItems)
//        super.init(nibName: nil, bundle: nil)
//    }
//
//    @available(*, unavailable)
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) is not supported")
//    }
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        view.accessibilityViewIsModal = true
//        //view.backgroundColor = .blue
//    }
//
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        setupNavigationBar()
//        configureNavigationBarAppearance()
//        configureViews()
//    }
//
//    private func configureViews() {
//        segmentedControl.selectedSegmentIndex = 0
//
//        view.addSubview(segmentedControl)
//        configureConstraints()
//    }
//
//    private func configureConstraints() {
//        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
//            segmentedControl.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
//            segmentedControl.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor)
//        ])
//    }
//
//    private func setupNavigationBar() {
//        setupNavigationBarTitle("Meetings")
////        let button = AuthenticationNavigationBar.makeBackButton()
//        //navigationItem.leftBarButtonItem = UIBarButtonItem(customView: button)
//        setupLeftNavigationBarButtonItems()
//        setupRightNavigationBarButtonItems()
//    }
//
//    func configureNavigationBarAppearance() {
//        let appearance = UINavigationBarAppearance()
//        appearance.configureWithDefaultBackground()
//        appearance.backgroundColor = ColorTheme.Backgrounds.surface
//
//        // Configure appearance for different states
//        navigationController?.navigationBar.standardAppearance = appearance
//        navigationController?.navigationBar.scrollEdgeAppearance = appearance
//        navigationController?.navigationBar.compactAppearance = appearance
//    }
//
//    func setupLeftNavigationBarButtonItems() {
//
//        // in the design the left bar button items are very close to each other,
//        // so we'll use a stack view instead
//        let stackView = UIStackView()
//        stackView.spacing = 4
//
//        // avatar
//        let accountImageView = makeAccountImageView()
//        stackView.addArrangedSubview(accountImageView)
//        self.accountImageView = accountImageView
//
////        // legal hold
////        switch viewModel.selfUserLegalHoldSubject.legalHoldStatus {
////        case .disabled:
////            break
////        case .pending:
////            let pendingRequestView = createPendingLegalHoldRequestView()
////            stackView.addArrangedSubview(pendingRequestView)
////        case .enabled:
////            let legalHoldView = createLegalHoldView()
////            stackView.addArrangedSubview(legalHoldView)
////        }
////
////        // verification status
////        if viewModel.selfUserStatus.isE2EICertified {
////            let imageView = UIImageView(image: .init(resource: .certificateValid))
////            imageView.contentMode = .scaleAspectFit
////            stackView.addArrangedSubview(imageView)
////        }
////        if viewModel.selfUserStatus.isProteusVerified {
////            let imageView = UIImageView(image: .init(resource: .verifiedShield))
////            imageView.contentMode = .scaleAspectFit
////            stackView.addArrangedSubview(imageView)
////        }
//
//        navigationItem.leftBarButtonItems = [.init(customView: stackView)]
//    }
//
//    func setupRightNavigationBarButtonItems() {
//
//        let configuration = UIImage.SymbolConfiguration(font: .systemFont(ofSize: 17))
//        let actionImage = UIImage(systemName: "chevron.forward", withConfiguration: configuration)
//        let joinNowAction = UIAction(title: "Meet Now", image: actionImage) { _ in }
//        let scheduleMeetingAction = UIAction(title: "Schedule a Meeting", image: actionImage) { _ in }
//
//        let menuChildren = [
//            joinNowAction,
//            scheduleMeetingAction
//        ]
//        let filterMenu = UIMenu(children: menuChildren)
//
//        let symbolConfiguration = UIImage.SymbolConfiguration(weight: .semibold)
//        let startMeetingImage = UIImage(systemName: "video.fill", withConfiguration: symbolConfiguration)!
//        let startMeetingButton = UIButton(type: .system)
//        startMeetingButton.setImage(startMeetingImage, for: .normal)
//        startMeetingButton.showsMenuAsPrimaryAction = true
//        startMeetingButton.accessibilityLabel = L10n.Accessibility.ConversationsList.FilterButton.description
//        startMeetingButton.menu = filterMenu
//        let startMeetingItem = UIBarButtonItem(customView: startMeetingButton)
//
//        navigationItem.rightBarButtonItems = [startMeetingItem]
//
//    }
//
//    // MARK: - Navigation Bar Items
//
//    private func makeAccountImageView() -> AccountImageView {
//
//        let accountImageView = AccountImageView()
////        accountImageView.source = viewModel.accountImageSource
////        accountImageView.availability = viewModel.selfUserStatus.availability.mapToAccountImageAvailability()
////        accountImageView.hideProfileNotificationsBadge = viewModel.hideProfileNotificationsBadge
//        accountImageView.isAccessibilityElement = true
////        accountImageView.accessibilityValue = L10n.Localizable.ConversationList.Header.SelfTeam
////            .accessibilityValue(viewModel.userSession.selfUser.name ?? "")
//        accountImageView.accessibilityHint = L10n.Accessibility.ConversationsList.AccountButton.hint
//        accountImageView.translatesAutoresizingMaskIntoConstraints = false
//        accountImageView.widthAnchor.constraint(equalToConstant: 28).isActive = true
//        accountImageView.heightAnchor.constraint(equalToConstant: 28).isActive = true
//
//        let design = AccountImageViewDesign()
//        accountImageView.imageBorderWidth = design.borderWidth
//        accountImageView.imageBorderColor = design.borderColor
//        accountImageView.availableColor = design.availabilityIndicator.availableColor
//        accountImageView.busyColor = design.availabilityIndicator.busyColor
//        accountImageView.awayColor = design.availabilityIndicator.awayColor
//        accountImageView.availabilityIndicatorBackgroundColor = design.availabilityIndicator.backgroundViewColor
//
//        accountImageView.translatesAutoresizingMaskIntoConstraints = false
//        accountImageView.widthAnchor.constraint(equalToConstant: 28).isActive = true
//        accountImageView.heightAnchor.constraint(equalToConstant: 28).isActive = true
//
//        return accountImageView
//    }
//
//}
//

final class MeetingsViewController: UIViewController {

    private let viewModel: MeetingsViewModel
    private let hostingController: UIHostingController<MeetingsView>
    private weak var accountImageView: AccountImageView?

    init(viewModel: MeetingsViewModel = .init()) {
        self.viewModel = viewModel
        self.hostingController = UIHostingController(rootView: MeetingsView(viewModel: viewModel))
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.accessibilityViewIsModal = true
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)

        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        setupNavigationBar()
        configureNavigationBarAppearance()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Keep nav appearance in sync in case parent controller changes it
        configureNavigationBarAppearance()
    }

    // MARK: - Navigation Bar

    private func setupNavigationBar() {
        navigationItem.title = "Meetings"
        setupLeftNavigationBarButtonItems()
        setupRightNavigationBarButtonItems()
    }

    func configureNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = ColorTheme.Backgrounds.surface

        // Configure appearance for different states
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
    }



    private func setupLeftNavigationBarButtonItems() {
        let stackView = UIStackView()
        stackView.spacing = 6
        stackView.axis = .horizontal
        stackView.alignment = .center

        let avatar = makeAccountImageView()
        stackView.addArrangedSubview(avatar)
        self.accountImageView = avatar

        let container = UIBarButtonItem(customView: stackView)
        navigationItem.leftBarButtonItems = [container]
    }

    private func setupRightNavigationBarButtonItems() {
        let configuration = UIImage.SymbolConfiguration(font: .systemFont(ofSize: 17))
        let chevron = UIImage(systemName: "chevron.forward", withConfiguration: configuration)

        let meetNow = UIAction(title: "Meet Now", image: chevron) { [weak self] _ in
            self?.viewModel.meetNowTapped()
        }
        let schedule = UIAction(title: "Schedule a Meeting", image: chevron) { [weak self] _ in
            self?.viewModel.scheduleMeetingTapped()
        }

        let menu = UIMenu(children: [meetNow, schedule])

        let symbolConfiguration = UIImage.SymbolConfiguration(weight: .semibold)
        let video = UIImage(systemName: "video.fill", withConfiguration: symbolConfiguration)

        let button = UIButton(type: .system)
        button.setImage(video, for: .normal)
        button.accessibilityLabel = "Start or schedule a meeting"
        button.showsMenuAsPrimaryAction = true
        button.menu = menu

        let item = UIBarButtonItem(customView: button)
        navigationItem.rightBarButtonItems = [item]
    }

    private func makeAccountImageView() -> AccountImageView {
        let v = AccountImageView()
        v.isAccessibilityElement = true
        v.accessibilityHint = viewModel.accessibilityHintForAvatar
        v.translatesAutoresizingMaskIntoConstraints = false
        v.widthAnchor.constraint(equalToConstant: 28).isActive = true
        v.heightAnchor.constraint(equalToConstant: 28).isActive = true
        return v
    }
}
