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

public import SwiftUI
import Foundation
import WireAccountImageUI
import WireDesign
import Combine

public final class MeetingsListViewController: UIViewController {

    private typealias Strings = L10n.Localizable.WireMeetings.List.Actions

    private let viewModel: MeetingsListViewModel
    private let hostingController: UIHostingController<MeetingsListView>
    private var cancellables = Set<AnyCancellable>()
    private var accountWrapperView: AccountUIWrapperView?

    public init(viewModel: MeetingsListViewModel) {
        self.viewModel = viewModel
        self.hostingController = UIHostingController(rootView: MeetingsListView(viewModel: viewModel))
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    public override func viewDidLoad() {
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
        viewModel.$account
            .receive(on: RunLoop.main)
            .sink { [weak self] newAccount in
                self?.accountWrapperView?.apply(account: newAccount)
            }
            .store(in: &cancellables)
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBarAppearance()
    }

    // MARK: - Navigation Bar

    private func setupNavigationBar() {
        navigationItem.title = L10n.Localizable.WireMeetings.List.title
        setupLeftNavigationBarButtonItems()
        setupRightNavigationBarButtonItems()
    }

    func configureNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = ColorTheme.Backgrounds.surface

        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
    }

    private func setupRightNavigationBarButtonItems() {
        let configuration = UIImage.SymbolConfiguration(font: .systemFont(ofSize: 17))
        let chevron = UIImage(systemName: "chevron.forward", withConfiguration: configuration)

        let meetNow = UIAction(title: Strings.meetNow, image: chevron) { [weak self] _ in
            self?.viewModel.meetNowTapped()
        }
        let schedule = UIAction(title: Strings.scheduleMeeting, image: chevron) { [weak self] _ in
            self?.viewModel.scheduleMeetingTapped()
        }

        let menu = UIMenu(children: [meetNow, schedule])
        let button = UIButton(type: .system)
        button.setImage(UIImage(resource: .videoCall), for: .normal)
        button.showsMenuAsPrimaryAction = true
        button.menu = menu
        button.accessibilityIdentifier = "scheduleMeetingBarButton"

        let item = UIBarButtonItem(customView: button)
        navigationItem.rightBarButtonItems = [item]
    }

    private func setupLeftNavigationBarButtonItems() {
        let stackView = UIStackView()
        stackView.spacing = 6
        stackView.axis = .horizontal
        stackView.alignment = .center

        let avatar = makeAccountImageView()
        stackView.addArrangedSubview(avatar)
        accountWrapperView = avatar

        let container = UIBarButtonItem(customView: stackView)
        container.accessibilityIdentifier = "accountImageBarButton"
        navigationItem.leftBarButtonItems = [container]
    }

    private func makeAccountImageView() -> AccountUIWrapperView {
        let accountUI = AccountUIWrapperView(viewModel: viewModel.account)
        accountUI.isAccessibilityElement = true
        accountUI.translatesAutoresizingMaskIntoConstraints = false
        accountUI.widthAnchor.constraint(equalToConstant: 28).isActive = true
        accountUI.heightAnchor.constraint(equalToConstant: 28).isActive = true
        return accountUI
    }
}
