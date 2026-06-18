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

final class GroupDetailsDescriptionCell: UICollectionViewCell {

    let accessoryIconView = UIImageView()
    let descriptionTextView = UITextView()
    private let placeholderLabel = UILabel()
    var contentStackView: UIStackView!

    override init(frame: CGRect) {
        super.init(frame: frame)

        setup()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init?(coder aDecoder: NSCoder) is not implemented")
    }

    fileprivate func setup() {
        accessoryIconView.translatesAutoresizingMaskIntoConstraints = false
        accessoryIconView.contentMode = .scaleAspectFit
        accessoryIconView.setContentHuggingPriority(.required, for: .horizontal)
        accessoryIconView.setContentCompressionResistancePriority(.required, for: .horizontal)

        descriptionTextView.translatesAutoresizingMaskIntoConstraints = false
        descriptionTextView.font = FontSpec(.normal, .light).font!
        descriptionTextView.backgroundColor = .clear
        descriptionTextView.textContainerInset = .zero
        descriptionTextView.textContainer.lineFragmentPadding = 0
        descriptionTextView.isScrollEnabled = false
        descriptionTextView.returnKeyType = .done
        descriptionTextView.accessibilityIdentifier = "group_details.description_field"

        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        placeholderLabel.font = FontSpec(.normal, .light).font!
        placeholderLabel.text = L10n.Localizable.Participants.Section.Description.placeholder
        placeholderLabel.isUserInteractionEnabled = false

        contentStackView = UIStackView(arrangedSubviews: [descriptionTextView, accessoryIconView])
        contentStackView.axis = .horizontal
        contentStackView.distribution = .fill
        contentStackView.alignment = .top
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.spacing = 8

        contentView.addSubview(contentStackView)
        contentView.addSubview(placeholderLabel)

        NSLayoutConstraint.activate([
            contentStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            contentStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            contentStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            contentStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            placeholderLabel.leadingAnchor.constraint(equalTo: descriptionTextView.leadingAnchor),
            placeholderLabel.topAnchor.constraint(equalTo: descriptionTextView.topAnchor)
        ])

        configureColors()
    }

    func configure(for conversation: GroupDetailsConversationType, editable: Bool) {
        descriptionTextView.text = conversation.groupDescription
        descriptionTextView.isEditable = editable
        descriptionTextView.isSelectable = editable
        accessoryIconView.isHidden = !editable
        updatePlaceholderVisibility()
    }

    func updatePlaceholderVisibility() {
        placeholderLabel.isHidden = !(descriptionTextView.text?.isEmpty ?? true)
    }

    /// Returns the height needed to display the given text at the given collection view width.
    static func preferredHeight(for text: String?, width: CGFloat) -> CGFloat {
        let horizontalInsets: CGFloat = 24 + 16 + 8 + 16 // leading + trailing + spacing + pencil icon approx
        let textViewWidth = width - horizontalInsets
        let font = FontSpec(.normal, .light).font!
        let boundingSize = CGSize(width: textViewWidth, height: .greatestFiniteMagnitude)
        let textHeight = (text ?? " ").boundingRect(
            with: boundingSize,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        ).height
        return max(56, ceil(textHeight) + 32) // 32 = 2 × 16pt vertical padding
    }

    /// Returns the height this cell needs to display its current content at the given width.
    func preferredHeight(width: CGFloat) -> CGFloat {
        Self.preferredHeight(for: descriptionTextView.text, width: width)
    }

    private func configureColors() {
        backgroundColor = SemanticColors.View.backgroundUserCell
        accessoryIconView.setTemplateIcon(.pencil, size: .tiny)
        accessoryIconView.tintColor = SemanticColors.Icon.foregroundDefault
        descriptionTextView.textColor = SemanticColors.Label.textDefault
        placeholderLabel.textColor = SemanticColors.SearchBar.textInputViewPlaceholder
    }

}
