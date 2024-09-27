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

// MARK: - ParticipantDeviceHeaderViewDelegate

protocol ParticipantDeviceHeaderViewDelegate: AnyObject {
    func participantsDeviceHeaderViewDidTapLearnMore(_ headerView: ParticipantDeviceHeaderView)
}

// MARK: - ParticipantDeviceHeaderView

final class ParticipantDeviceHeaderView: UIView {
    // MARK: Lifecycle

    init(userName: String) {
        self.userName = userName

        super.init(frame: CGRect.zero)

        setup()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    let userName: String

    weak var delegate: ParticipantDeviceHeaderViewDelegate?

    var showUnencryptedLabel = false {
        didSet {
            textView.attributedText = attributedExplanationText(
                for: userName,
                showUnencryptedLabel: showUnencryptedLabel
            )
        }
    }

    var linkAttributes: [NSAttributedString.Key: Any] {
        [
            NSAttributedString.Key.font: font,
            NSAttributedString.Key.foregroundColor: linkAttributeColor,
            NSAttributedString.Key.link: WireURLs.shared.whyToVerifyFingerprintArticle,
            NSAttributedString.Key.paragraphStyle: paragraphStyleForFingerprint,
        ]
    }

    var paragraphStyleForFingerprint: NSMutableParagraphStyle {
        let paragraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        paragraphStyle.lineSpacing = 2

        return paragraphStyle
    }

    func setup() {
        backgroundColor = .clear
        setupViews()
        setupConstraints()
        setupAccessibility()
    }

    func setupViews() {
        textView.textContainer.maximumNumberOfLines = 0
        textView.delegate = self
        textView.linkTextAttributes = [:]

        addSubview(textView)
    }

    // MARK: Attributed Text

    func attributedExplanationText(
        for userName: String,
        showUnencryptedLabel unencrypted: Bool
    ) -> NSAttributedString? {
        typealias ProfileDevices = L10n.Localizable.Profile.Devices

        if unencrypted {
            let message = userName.isEmpty ? ProfileDevices.noDeviceData : ProfileDevices
                .fingerprintMessageUnencrypted(userName)
            return attributedFingerprint(forMessage: message)
        } else {
            let message =
                "\(ProfileDevices.FingerprintMessage.title(userName))\(L10n.Localizable.General.spaceBetweenWords)"

            let mutableAttributedString =
                NSMutableAttributedString(attributedString: attributedFingerprint(forMessage: message))

            let fingerprintLearnMoreLink = ProfileDevices.FingerprintMessage.link && linkAttributes

            return mutableAttributedString + fingerprintLearnMoreLink
        }
    }

    func attributedFingerprint(forMessage fingerprintExplanation: String) -> NSAttributedString {
        let textAttributes = [
            NSAttributedString.Key.foregroundColor: textColor,
            NSAttributedString.Key.font: font,
            NSAttributedString.Key.paragraphStyle: paragraphStyleForFingerprint,
        ]

        return NSAttributedString(string: fingerprintExplanation, attributes: textAttributes)
    }

    // MARK: Private

    private var font: UIFont = .normalLightFont
    private var textColor: UIColor = SemanticColors.Label.textSectionHeader
    private var linkAttributeColor: UIColor = .accent()
    private var textView = WebLinkTextView()

    private func setupConstraints() {
        textView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            textView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            textView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            textView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
        ])
    }

    private func setupAccessibility() {
        textView.accessibilityTraits = .link
        textView.accessibilityHint = L10n.Accessibility.DeviceDetails.WhyVerifyFingerprint.hint
    }
}

// MARK: UITextViewDelegate

extension ParticipantDeviceHeaderView: UITextViewDelegate {
    func textView(
        _ textView: UITextView,
        shouldInteractWith URL: URL,
        in characterRange: NSRange,
        interaction: UITextItemInteraction
    ) -> Bool {
        delegate?.participantsDeviceHeaderViewDidTapLearnMore(self)

        return false
    }
}
