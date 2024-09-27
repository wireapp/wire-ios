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
import WireDataModel
import WireDesign

private let smallLightFont = FontSpec(.small, .light)
private let smallBoldFont = FontSpec(.small, .medium)
private let normalBoldFont = FontSpec(.normal, .medium)

// MARK: - AddressBookCorrelationFormatter

final class AddressBookCorrelationFormatter: NSObject {
    // MARK: Lifecycle

    init(lightFont: FontSpec, boldFont: FontSpec, color: UIColor) {
        self.lightFont = lightFont
        self.boldFont = boldFont
        self.color = color
    }

    // MARK: Internal

    let lightFont, boldFont: FontSpec
    let color: UIColor

    func correlationText(for user: UserType, addressBookName: String?) -> NSAttributedString? {
        if let name = addressBookName, let addressBook = addressBookText(for: user, with: name) {
            return addressBook
        }

        return nil
    }

    // MARK: Private

    private func addressBookText(for user: UserType, with addressBookName: String) -> NSAttributedString? {
        guard !user.isSelfUser, let userName = user.name else {
            return nil
        }
        let suffix = L10n.Localizable.Conversation.ConnectionView.inAddressBook && lightFont.font! && color
        if addressBookName.lowercased() == userName.lowercased() {
            return suffix
        }

        let contactName = addressBookName && boldFont.font! && color
        return contactName + " " + suffix
    }
}

// MARK: - UserNameDetailViewModel

final class UserNameDetailViewModel: NSObject {
    // MARK: Lifecycle

    init(user: UserType?, fallbackName fallback: String, addressBookName: String?) {
        self.title = UserNameDetailViewModel.attributedTitle(for: user, fallback: fallback)
        self.handleText = UserNameDetailViewModel.attributedSubtitle(for: user)
        self.correlationText = UserNameDetailViewModel.attributedCorrelationText(
            for: user,
            addressBookName: addressBookName
        )
    }

    // MARK: Internal

    static var formatter = AddressBookCorrelationFormatter(
        lightFont: smallLightFont,
        boldFont: smallBoldFont,
        color: SemanticColors.Label.textDefault
    )

    let title: NSAttributedString

    var firstSubtitle: NSAttributedString? {
        handleText ?? correlationText
    }

    var secondSubtitle: NSAttributedString? {
        guard handleText != nil else {
            return nil
        }
        return correlationText
    }

    var firstAccessibilityIdentifier: String? {
        if handleText != nil {
            return "username"
        } else if correlationText != nil {
            return "correlation"
        }

        return nil
    }

    var secondAccessibilityIdentifier: String? {
        guard handleText != nil, correlationText != nil else {
            return nil
        }
        return "correlation"
    }

    static func attributedTitle(for user: UserType?, fallback: String) -> NSAttributedString {
        (user?.name ?? fallback) && normalBoldFont.font! && SemanticColors.Label.textDefault
    }

    static func attributedSubtitle(for user: UserType?) -> NSAttributedString? {
        guard let user, let handle = user.handleDisplayString(withDomain: user.isFederated) else {
            return nil
        }
        return handle && smallBoldFont.font! && SemanticColors.Label.textDefault
    }

    static func attributedCorrelationText(for user: UserType?, addressBookName: String?) -> NSAttributedString? {
        guard let user else {
            return nil
        }
        return formatter.correlationText(for: user, addressBookName: addressBookName)
    }

    // MARK: Private

    private let handleText: NSAttributedString?
    private let correlationText: NSAttributedString?
}

// MARK: - UserNameDetailView

final class UserNameDetailView: UIView, DynamicTypeCapable {
    // MARK: Lifecycle

    // MARK: - Initialization

    init() {
        super.init(frame: .zero)
        setupViews()
        createConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    let subtitleLabel = UILabel()
    let correlationLabel = UILabel()

    // MARK: - Configure

    func configure(with model: UserNameDetailViewModel) {
        self.model = model
        subtitleLabel.attributedText = model.firstSubtitle
        correlationLabel.attributedText = model.secondSubtitle

        subtitleLabel.accessibilityIdentifier = model.firstAccessibilityIdentifier
        correlationLabel.accessibilityIdentifier = model.secondAccessibilityIdentifier
    }

    func redrawFont() {
        guard let model else {
            return
        }
        subtitleLabel.attributedText = model.firstSubtitle
        correlationLabel.attributedText = model.secondSubtitle
    }

    // MARK: Private

    // MARK: - Properties

    private var model: UserNameDetailViewModel?

    // MARK: - Layout - Private Methods

    private func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = SemanticColors.View.backgroundDefault

        for item in [subtitleLabel, correlationLabel] {
            item.textAlignment = .center
            item.backgroundColor = .clear
            addSubview(item)
        }
    }

    private func createConstraints() {
        for item in [subtitleLabel, correlationLabel] {
            item.translatesAutoresizingMaskIntoConstraints = false
        }
        NSLayoutConstraint.activate([
            subtitleLabel.topAnchor.constraint(equalTo: topAnchor),
            subtitleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            subtitleLabel.heightAnchor.constraint(equalToConstant: 16),

            correlationLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor),
            correlationLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            correlationLabel.heightAnchor.constraint(equalToConstant: 16),
            correlationLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
}
