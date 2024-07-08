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

import Foundation
import UIKit
import WireDataModel
import WireDesign

class ShareableDebugReportView: UIView {

    // MARK: - Views

    private let topLabel: UILabel = {
        let topLabel = UILabel()
        topLabel.numberOfLines = 1
        topLabel.lineBreakMode = .byTruncatingMiddle
        return topLabel
    }()

    private let bottomLabel: UILabel = {
        let bottomLabel = UILabel()
        bottomLabel.numberOfLines = 1
        return bottomLabel
    }()

    private let labelsView = UIView()

    private let documentIconView: UIImageView = {
        let documentIconView = UIImageView()
        documentIconView.tintColor = SemanticColors.Icon.backgroundDefault
        documentIconView.contentMode = .center
        documentIconView.setTemplateIcon(.document, size: .small)
        return documentIconView
    }()

    // MARK: - Life cycle

    convenience init() {
        self.init(frame: .zero)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        createConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

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
            documentIconView
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            topLabel.topAnchor.constraint(equalTo: labelsView.topAnchor),
            topLabel.leftAnchor.constraint(equalTo: labelsView.leftAnchor),
            topLabel.rightAnchor.constraint(equalTo: labelsView.rightAnchor),

            bottomLabel.topAnchor.constraint(equalTo: topLabel.bottomAnchor, constant: 2),
            bottomLabel.leftAnchor.constraint(equalTo: labelsView.leftAnchor),
            bottomLabel.rightAnchor.constraint(equalTo: labelsView.rightAnchor),
            bottomLabel.bottomAnchor.constraint(equalTo: labelsView.bottomAnchor),

            labelsView.leftAnchor.constraint(equalTo: documentIconView.rightAnchor, constant: 12),
            labelsView.rightAnchor.constraint(equalTo: rightAnchor, constant: -12),
            labelsView.centerYAnchor.constraint(equalTo: centerYAnchor),

            documentIconView.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            documentIconView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            documentIconView.widthAnchor.constraint(equalToConstant: 32),
            documentIconView.heightAnchor.constraint(equalToConstant: 32),
            documentIconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            documentIconView.leftAnchor.constraint(equalTo: leftAnchor, constant: 12)
        ])
    }

    // MARK: - Interface

    func configure(with fileMetadata: ZMFileMetadata) {

        let ext = (fileMetadata.filename as NSString).pathExtension
        let dot = String.MessageToolbox.middleDot
        let fileSize = ByteCountFormatter.string(
            fromByteCount: Int64(fileMetadata.size),
            countStyle: .binary
        )

        let firstLine = fileMetadata.filename.uppercased()
        let secondLine = "\(fileSize) \(dot) \(ext)".uppercased()

        topLabel.attributedText = firstLine && UIFont.smallSemiboldFont && SemanticColors.Label.textDefault
        bottomLabel.attributedText = secondLine && UIFont.smallLightFont && SemanticColors.Label.textCollectionSecondary

        topLabel.accessibilityValue = topLabel.attributedText?.string ?? ""
        bottomLabel.accessibilityValue = bottomLabel.attributedText?.string ?? ""
    }
}
