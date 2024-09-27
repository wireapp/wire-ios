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
import WireDataModel
import WireDesign

class ShareableDebugReportView: UIView {
    // MARK: Lifecycle

    convenience init() {
        self.init(frame: .zero)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        createConstraints()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    // MARK: - Interface

    func configure(with fileMetadata: ZMFileMetadata) {
        let ext = (fileMetadata.filename as NSString).pathExtension
        let dot = String.MessageToolbox.middleDot
        let fileSize = ByteCountFormatter.string(
            fromByteCount: Int64(fileMetadata.size),
            countStyle: .binary
        )

        topLabel.text = fileMetadata.filename.uppercased()
        bottomLabel.text = "\(fileSize) \(dot) \(ext)".uppercased()

        topLabel.accessibilityValue = topLabel.text ?? ""
        bottomLabel.accessibilityValue = bottomLabel.text ?? ""
    }

    // MARK: Private

    // MARK: - Constants

    private enum LayoutConstants {
        static let spacing: CGFloat = 2
        static let padding: CGFloat = 12
        static let iconSize: CGFloat = 28
    }

    // MARK: - Views

    private var topLabel: DynamicFontLabel = {
        let label = DynamicFontLabel(
            style: .body3,
            color: SemanticColors.Label.textDefault
        )
        label.numberOfLines = 0
        label.font = label.font.withSize(14)

        return label
    }()

    private var bottomLabel: DynamicFontLabel = {
        let label = DynamicFontLabel(
            style: .body1,
            color: SemanticColors.Label.textCollectionSecondary
        )
        label.numberOfLines = 0
        label.font = label.font.withSize(14)

        return label
    }()

    private let labelsView = UIView()

    private var documentIconView: UIImageView = {
        let documentIconView = UIImageView(image: .init(resource: .file).withRenderingMode(.alwaysTemplate))
        documentIconView.tintColor = SemanticColors.Icon.backgroundDefault
        documentIconView.contentMode = .scaleAspectFit
        return documentIconView
    }()

    // MARK: - Setup

    private func setupViews() {
        addSubview(labelsView)
        addSubview(documentIconView)
        labelsView.addSubview(topLabel)
        labelsView.addSubview(bottomLabel)
    }

    private func createConstraints() {
        [
            labelsView,
            topLabel,
            bottomLabel,
            documentIconView,
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            topLabel.topAnchor.constraint(equalTo: labelsView.topAnchor),
            topLabel.leftAnchor.constraint(equalTo: labelsView.leftAnchor),
            topLabel.rightAnchor.constraint(equalTo: labelsView.rightAnchor),

            bottomLabel.topAnchor.constraint(equalTo: topLabel.bottomAnchor, constant: LayoutConstants.spacing),
            bottomLabel.leftAnchor.constraint(equalTo: labelsView.leftAnchor),
            bottomLabel.rightAnchor.constraint(equalTo: labelsView.rightAnchor),
            bottomLabel.bottomAnchor.constraint(equalTo: labelsView.bottomAnchor),

            labelsView.leftAnchor.constraint(equalTo: documentIconView.rightAnchor, constant: LayoutConstants.padding),
            labelsView.rightAnchor.constraint(equalTo: rightAnchor, constant: -LayoutConstants.padding),
            labelsView.topAnchor.constraint(equalTo: topAnchor, constant: LayoutConstants.padding),
            labelsView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -LayoutConstants.padding),
            labelsView.centerYAnchor.constraint(equalTo: centerYAnchor),
            labelsView.heightAnchor.constraint(greaterThanOrEqualTo: documentIconView.heightAnchor),

            documentIconView.widthAnchor.constraint(equalToConstant: LayoutConstants.iconSize),
            documentIconView.heightAnchor.constraint(equalToConstant: LayoutConstants.iconSize),
            documentIconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            documentIconView.leftAnchor.constraint(equalTo: leftAnchor, constant: LayoutConstants.padding),
        ])
    }
}
