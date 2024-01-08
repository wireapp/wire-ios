//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

import Foundation
import UIKit
import WireCommonComponents

private enum EmptySearchResultsViewState {
    case noUsers
    case noServices
    case everyoneAdded
    case noServicesEnabled
}

enum EmptySearchResultsViewAction {
    case openManageServices
    case openSearchSupportPage
}

extension EmptySearchResultsViewAction {
    var title: String {
        switch self {
        case .openManageServices:
            return L10n.Localizable.Peoplepicker.NoMatchingResults.Action.manageServices
        case .openSearchSupportPage:
            return L10n.Localizable.Peoplepicker.NoMatchingResults.Action.learnMore
        }
    }
}

protocol EmptySearchResultsViewDelegate: AnyObject {
    func execute(action: EmptySearchResultsViewAction, from: EmptySearchResultsView)
}

final class EmptySearchResultsView: UIView {

    typealias LabelColors = SemanticColors.Label

    private var state: EmptySearchResultsViewState = .noUsers {
        didSet {
            iconView.image = icon
            iconView.tintColor = iconColor
            statusLabel.text = self.text

            if let action = self.buttonAction {
                actionButton.isHidden = false
                actionButton.setup(title: action.title)
            } else {
                actionButton.isHidden = true
            }
        }
    }

    func updateStatus(searchingForServices: Bool, hasFilter: Bool) {
        switch (searchingForServices, hasFilter) {
        case (true, false):
            self.state = .noServicesEnabled
        case (true, true):
            self.state = .noServices
        case (false, true):
            self.state = .noUsers
        case (false, false):
            self.state = .everyoneAdded
        }
    }

    private let isSelfUserAdmin: Bool
    private let isFederationEnabled: Bool

    /// Contains the `stackView`.
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private let iconView = UIImageView()
    private let statusLabel = DynamicFontLabel(fontSpec: .normalRegularFont, color: LabelColors.textSettingsPasswordPlaceholder)
    private let actionButton = LinkButton(fontSpec: .normalRegularFont)
    private let iconColor = LabelColors.textSettingsPasswordPlaceholder

    weak var delegate: EmptySearchResultsViewDelegate?

    init(
        isSelfUserAdmin: Bool,
        isFederationEnabled: Bool
    ) {
        self.isSelfUserAdmin = isSelfUserAdmin
        self.isFederationEnabled = isFederationEnabled

        super.init(frame: .zero)

        [scrollView, stackView, iconView, statusLabel, actionButton].prepareForLayout()
        [iconView, statusLabel, actionButton].forEach(stackView.addArrangedSubview)

        addSubview(scrollView)
        scrollView.addSubview(stackView)

        NSLayoutConstraint.activate([

            // scroll view with empty search results view
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),

            // stack view within scroll view
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            scrollView.contentLayoutGuide.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            scrollView.contentLayoutGuide.bottomAnchor.constraint(equalTo: stackView.bottomAnchor),
            stackView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor)
        ])

        stackView.alignment = .center
        stackView.spacing = 16
        stackView.axis = .vertical
        stackView.alignment = .center

        statusLabel.numberOfLines = 0
        statusLabel.preferredMaxLayoutWidth = 200
        statusLabel.textAlignment = .center

        actionButton.accessibilityIdentifier = "button.searchui.open-services-no-results"

        actionButton.addCallback(for: .touchUpInside) { [unowned self] _ in
            guard let action = self.buttonAction else {
                return
            }
            self.delegate?.execute(action: action, from: self)
        }

        state = .noUsers
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

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
        }
    }

    private var icon: UIImage {
        let icon: StyleKitIcon

        switch state {
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
            return .openManageServices
        case .noUsers:
            return .openSearchSupportPage
        default:
            return nil
        }
    }
}
