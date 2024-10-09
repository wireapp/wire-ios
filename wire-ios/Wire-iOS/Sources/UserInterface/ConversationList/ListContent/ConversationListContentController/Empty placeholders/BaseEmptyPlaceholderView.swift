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

final class BaseEmptyPlaceholderView: UIStackView {

    // MARK: - Init

    init(
        title: String,
        description: NSAttributedString
    ) {
        super.init(frame: .zero)

        setup(title: title, description: description)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setup(title: String, description: NSAttributedString) {
        let titleLabel = DynamicFontLabel(
            text: title,
            style: .h2,
            color: SemanticColors.Label.textDefault)

        let descriptionLabel = SubheadlineTextView(
            attributedText: description,
            style: .body1,
            color: SemanticColors.Label.textDefault)

        titleLabel.textAlignment = .center
        descriptionLabel.textAlignment = .center
        addArrangedSubview(titleLabel)
        addArrangedSubview(descriptionLabel)
        axis = .vertical
        spacing = 10
        translatesAutoresizingMaskIntoConstraints = false
    }

}
