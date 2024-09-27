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
import WireCommonComponents
import WireDesign

// MARK: - EmptySearchResultsViewState

private enum EmptySearchResultsViewState {
    case initialSearch
    case noUsers
    case noServices
    case everyoneAdded
    case noServicesEnabled
}

// MARK: - EmptySearchResultsViewAction

enum EmptySearchResultsViewAction {
    case openManageServices
    case openSearchSupportPage
}

extension EmptySearchResultsViewAction {
    var title: String {
        switch self {
        case .openManageServices:
            L10n.Localizable.Peoplepicker.NoMatchingResults.Action.manageServices
        case .openSearchSupportPage:
            L10n.Localizable.Peoplepicker.NoMatchingResults.Action.learnMore
        }
    }
}

// MARK: - EmptySearchResultsViewDelegate

protocol EmptySearchResultsViewDelegate: AnyObject {
    func execute(action: EmptySearchResultsViewAction, from: EmptySearchResultsView)
}

// MARK: - EmptySearchResultsView

final class EmptySearchResultsView: UIView {
    // MARK: Lifecycle

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

        updateUIForCurrentEmptySearchResultState()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    typealias LabelColors = SemanticColors.Label

    weak var delegate: EmptySearchResultsViewDelegate?

    // MARK: - Public Interface

    func updateStatus(searchingForServices: Bool, hasFilter: Bool) {
        switch (searchingForServices, hasFilter) {
        case (true, false):
            state = .noServicesEnabled
        case (true, true):
            state = .noServices
        case (false, true):
            state = .noUsers
        case (false, false):
            state = .initialSearch
        }
    }

    // MARK: Fileprivate

    // MARK: - Computed Properties

    fileprivate var state: EmptySearchResultsViewState = .initialSearch {
        didSet {
            updateUIForCurrentEmptySearchResultState()
        }
    }

    // MARK: Private

    // MARK: - Properties

    private let isSelfUserAdmin: Bool
    private let isFederationEnabled: Bool

    /// Contains the `stackView`.
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private let iconView = UIImageView()
    private let statusLabel = DynamicFontLabel(
        fontSpec: .normalRegularFont,
        color: LabelColors.textSettingsPasswordPlaceholder
    )
    private let actionButton = LinkButton(fontSpec: .normalRegularFont)
    private let iconColor = LabelColors.textSettingsPasswordPlaceholder

    private var text: String {
        typealias Message = L10n.Localizable.Peoplepicker.NoMatchingResults.Message

        switch state {
        case .everyoneAdded:
            return Message.usersAllAdded

        case .noUsers:
            if isFederationEnabled {
                return Message.usersAndFederation
            } else {
                return Message.users
            }

        case .noServices:
            return Message.services

        case .noServicesEnabled:
            if isSelfUserAdmin {
                return Message.servicesNotEnabledAdmin
            } else {
                return Message.servicesNotEnabled
            }

        case .initialSearch:
            return ""
        }
    }

    private var icon: UIImage {
        let icon: StyleKitIcon

        switch state {
        case .initialSearch:
            return UIImage()
        case .noServices, .noServicesEnabled:
            icon = .bot
        default:
            icon = .personalProfile
        }

        return icon.makeImage(size: .large, color: iconColor)
    }

    private var buttonAction: EmptySearchResultsViewAction? {
        switch state {
        case .noServicesEnabled where isSelfUserAdmin:
            .openManageServices
        case .noUsers:
            .openSearchSupportPage
        default:
            nil
        }
    }

    // MARK: - Private methods

    private func setupConstraints() {
        [
            scrollView,
            stackView,
            iconView,
            statusLabel,
            actionButton,
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            // scroll view with empty search results view
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            // Center the stackView within the scrollView
            stackView.centerXAnchor.constraint(equalTo: scrollView.frameLayoutGuide.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: scrollView.frameLayoutGuide.centerYAnchor),
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

    private func updateUIForCurrentEmptySearchResultState() {
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
    let view = EmptySearchResultsView(
        isSelfUserAdmin: true,
        isFederationEnabled: false
    )

    view.state = .noServicesEnabled
    return view
}
