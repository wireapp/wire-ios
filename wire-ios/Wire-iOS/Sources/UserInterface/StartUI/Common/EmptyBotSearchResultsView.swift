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

import SwiftUI
import WireSearchUI
import WireCommonComponents
import WireDesign

// MARK: - EmptyBotSearchResultsViewState

private enum EmptyBotSearchResultsViewState {
    case initialSearch
    case noUsers
    case everyoneAdded
    case noApps
    case noAppsEnabled
}

// MARK: - EmptyBotSearchResultsViewAction

enum EmptyBotSearchResultsViewAction {
    case openManageServices
    case openSearchSupportPage
}

extension EmptyBotSearchResultsViewAction {
    var title: String {
        switch self {
        case .openManageServices:
            L10n.Localizable.Peoplepicker.NoMatchingResults.Action.manageApps
        case .openSearchSupportPage:
            L10n.Localizable.Peoplepicker.NoMatchingResults.Action.learnMore
        }
    }
}

// MARK: - EmptyBotSearchResultsViewDelegate

protocol EmptyBotSearchResultsViewDelegate: AnyObject {
    func execute(action: EmptyBotSearchResultsViewAction, from: EmptyBotSearchResultsView)
}

// MARK: - EmptyBotSearchResultsView

final class EmptyBotSearchResultsView: UIView, EmptySearchResultsViewProtocol {

    typealias LabelColors = SemanticColors.Label

    // MARK: - Computed Properties

    fileprivate var state: EmptyBotSearchResultsViewState = .initialSearch {
        didSet {
            updateUIForCurrentEmptyBotSearchResultstate()
        }
    }

    private var text: String {
        typealias Message = L10n.Localizable.Peoplepicker.NoMatchingResults.Message

        return switch state {
        case .everyoneAdded:
            Message.usersAllAdded
        case .noUsers where isFederationEnabled:
            Message.usersAndFederation
        case .noUsers:
            Message.users
        case .noApps:
            Message.apps
        case .noAppsEnabled where isSelfUserAdmin:
            Message.appsNotEnabledAdmin
        case .noAppsEnabled:
            Message.appsNotEnabled
        case .initialSearch:
            ""
        }
    }

    private var icon: UIImage {
        let icon: StyleKitIcon

        switch state {
        case .initialSearch:
            return UIImage()
        case .noApps, .noAppsEnabled:
            icon = .bot
        default:
            icon = .personalProfile
        }

        return icon.makeImage(size: .large, color: iconColor)
    }

    private var buttonAction: EmptyBotSearchResultsViewAction? {
        switch state {
        case .noAppsEnabled where isSelfUserAdmin:
            .openManageServices
        case .noUsers:
            .openSearchSupportPage
        default:
            nil
        }
    }

    // MARK: - Properties

    private let isSelfUserAdmin: Bool
    private let isFederationEnabled: Bool

    /// Contains the `stackView`.
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private let iconView = UIImageView()
    private let statusLabel = DynamicFontLabel(style: .body1, color: LabelColors.textSettingsPasswordPlaceholder)
    private let actionButton = LinkButton(style: .body1)
    private let iconColor = LabelColors.textSettingsPasswordPlaceholder

    weak var delegate: EmptyBotSearchResultsViewDelegate?

    // MARK: Init

    init(
        isSelfUserAdmin: Bool,
        isFederationEnabled: Bool
    ) {
        self.isSelfUserAdmin = isSelfUserAdmin
        self.isFederationEnabled = isFederationEnabled

        super.init(frame: .zero)

        [iconView, statusLabel, actionButton].forEach(stackView.addArrangedSubview)

        addSubview(scrollView)
        scrollView.addSubview(stackView)

        setupConstraints()

        setUpStackView()

        setupStatusLabel()

        actionButton.accessibilityIdentifier = "button.searchui.open-services-no-results"

        actionButton.addCallback(for: .touchUpInside) { [unowned self] _ in
            guard let action = buttonAction else {
                return
            }
            delegate?.execute(action: action, from: self)
        }

        updateUIForCurrentEmptyBotSearchResultstate()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public Interface

    func updateStatus(searchingForApps: Bool, hasFilter: Bool) {
        switch (searchingForApps, hasFilter) {
        case (true, false):
            state = .noAppsEnabled
        case (true, true):
            state = .noApps
        case (false, true):
            state = .noUsers
        case (false, false):
            state = .initialSearch
        }
    }

    // MARK: - Private methods

    private func setupConstraints() {
        [
            scrollView,
            stackView,
            iconView,
            statusLabel,
            actionButton
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            // scroll view with empty search results view
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            // Center the stackView within the scrollView
            stackView.centerXAnchor.constraint(equalTo: scrollView.frameLayoutGuide.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: scrollView.frameLayoutGuide.centerYAnchor)
        ])
    }

    private func setUpStackView() {
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 16
    }

    private func setupStatusLabel() {
        statusLabel.numberOfLines = 0
        statusLabel.preferredMaxLayoutWidth = 200
        statusLabel.textAlignment = .center
    }

    private func updateUIForCurrentEmptyBotSearchResultstate() {
        iconView.image = icon
        iconView.tintColor = iconColor
        statusLabel.text = text

        if let action = buttonAction {
            actionButton.isHidden = false
            actionButton.setup(title: action.title)
        } else {
            actionButton.isHidden = true
        }
    }
}

// MARK: - Previews

@available(iOS 17, *)
#Preview {
    let view = EmptyBotSearchResultsView(
        isSelfUserAdmin: true,
        isFederationEnabled: false
    )
    view.state = .noAppsEnabled
    return view
}
