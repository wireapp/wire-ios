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
import WireDesign

final class EmptyPlaceholderView: UIView {

    var titleLabel: DynamicFontLabel!
    var descriptionLabel: SubheadlineTextView!

    let arrowImageView: UIImageView = {
        let arrow = UIImageView()
        arrow.image = UIImage(resource: .ConversationList.arrow)
        arrow.contentMode = .scaleAspectFit
        arrow.translatesAutoresizingMaskIntoConstraints = false
        return arrow
    }()

    // MARK: - Init

    init(content: ConversationListViewModel.EmptyPlaceholder) {
        super.init(frame: .zero)

        setup(content)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setup(_ content: ConversationListViewModel.EmptyPlaceholder) {
        titleLabel = DynamicFontLabel(
            text: content.headline,
            style: .h2,
            color: SemanticColors.Label.textDefault)

        descriptionLabel = SubheadlineTextView(
            attributedText: content.subheadline,
            style: .body1,
            color: SemanticColors.Label.textDefault)

        titleLabel.textAlignment = .center
        descriptionLabel.textAlignment = .center
        arrowImageView.isHidden = !content.showArrow

        let stackView = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel])
        stackView.axis = .vertical
        stackView.spacing = 2
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        addSubview(arrowImageView)

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),

            stackView.widthAnchor.constraint(lessThanOrEqualToConstant: 272),
            arrowImageView.topAnchor.constraint(equalTo: topAnchor),
            arrowImageView.bottomAnchor.constraint(equalTo: stackView.topAnchor, constant: -20),
            arrowImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20)
        ])
    }

    func configure(with content: ConversationListViewModel.EmptyPlaceholder) {
        titleLabel.text = content.headline
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.font(for: .body1),
            .foregroundColor: SemanticColors.Label.textDefault,
            .paragraphStyle: paragraphStyle
        ]
        descriptionLabel.attributedText = content.subheadline && textAttributes
        arrowImageView.isHidden = !content.showArrow
    }

}
