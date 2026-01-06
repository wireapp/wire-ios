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

import UIKit
import WireCommonComponents
import WireDataModel
import WireDesign

final class ConversationChannelHistoryAvailableCellDescription: ConversationMessageCellDescription {

    // MARK: Properties

    typealias View = ConversationChannelHistoryAvailableCell
    let configuration: View.Configuration

    weak var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    let containsHighlightableContent: Bool = false

    let accessibilityIdentifier: String? = nil
    let accessibilityLabel: String? = nil

    // MARK: initialization

    init(hasMoreHistory: Bool) {
        let image = hasMoreHistory ? UIImage(systemName: "arrow.trianglehead.counterclockwise") : nil
        let title = hasMoreHistory ? L10n.Localizable.Content.System.messageMoreHistoryAvailable : L10n.Localizable
            .Content.System.messageNoMoreHistoryAvailable
        self.configuration = View.Configuration(image: image, title: title)
        self.actionController = nil
    }

    init(configuration: View.Configuration) {
        self.configuration = configuration
    }

}

// MARK: ConversationChannelHistoryAvailableCell

final class ConversationChannelHistoryAvailableCell: UIView, ConversationMessageCell {

    // MARK: Properties

    struct Configuration: Equatable {
        let image: UIImage?
        let title: String
    }

    weak var delegate: ConversationMessageCellDelegate?
    weak var message: ZMConversationMessage?
    weak var actionController: ConversationMessageActionController?

    private let containerView = UIView()
    private let stackView = UIStackView()
    private let titleLabel = UILabel()
    private let imageView = UIImageView()
    var isSelected: Bool = false

    // MARK: initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        createConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Setup UI

    private func setupViews() {
        containerView.backgroundColor = SemanticColors.Label.textDefaultWhite
        containerView.layer.cornerRadius = 10
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)

        stackView.axis = .horizontal
        stackView.spacing = 5
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(stackView)

        [imageView, titleLabel].forEach(stackView.addArrangedSubview)
        imageView.image = UIImage(systemName: "arrow.trianglehead.counterclockwise")
        imageView.tintColor = SemanticColors.Icon.foregroundDefault
        titleLabel.numberOfLines = 0
        titleLabel.textColor = SemanticColors.Label.textDefault
        titleLabel.font = FontSpec.smallFont.font!
    }

    private func createConstraints() {
        let padding: CGFloat = 10

        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: padding),
            imageView.heightAnchor.constraint(equalToConstant: padding)
        ])

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: padding),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: padding),
            containerView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: padding),
            containerView.bottomAnchor.constraint(equalTo: stackView.bottomAnchor, constant: padding)
        ])

        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    // MARK: Configuration and actions

    func configure(with object: Configuration, animated: Bool) {
        imageView.image = object.image
        imageView.isHidden = object.image == nil
        titleLabel.text = object.title
    }
}
