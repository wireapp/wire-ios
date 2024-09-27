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
import WireDesign
import WireSyncEngine
import WireUtilities

final class CallParticipantDetailsView: RoundedBlurView {
    // MARK: Lifecycle

    // MARK: - Init

    override init() {
        self.nameLabel = DynamicFontLabel(
            fontSpec: .mediumRegularFont,
            color: SemanticColors.Label.textWhite
        )
        self.connectingLabel = DynamicFontLabel(
            fontSpec: .smallSemiboldFont,
            color: SemanticColors.Label.textParticipantDisconnected
        )
        connectingLabel.text = L10n.Localizable.Call.Grid.connecting
        super.init()
    }

    // MARK: Internal

    // MARK: - Properties

    typealias IconColors = SemanticColors.Icon

    var name: String? {
        didSet {
            nameLabel.text = name
        }
    }

    var microphoneIconStyle: MicrophoneIconStyle = .hidden {
        didSet {
            updateMicrophoneView()
        }
    }

    var callState: CallParticipantState = .connecting {
        didSet {
            switch callState {
            case .connecting, .unconnectedButMayConnect:
                connectingLabel.isHidden = false
                nameLabel.textColor = SemanticColors.Label.textInactive

            default:
                nameLabel.textColor = SemanticColors.Label.textWhite
                connectingLabel.isHidden = true
            }
        }
    }

    // MARK: - Setup Views

    override func setupViews() {
        super.setupViews()
        for item in [microphoneImageView, labelsContainerView] {
            item.translatesAutoresizingMaskIntoConstraints = false
            addSubview(item)
        }
        for item in [nameLabel, connectingLabel] {
            item.translatesAutoresizingMaskIntoConstraints = false
            labelsContainerView.addArrangedSubview(item)
        }
        connectingLabel.isHidden = true
        connectingLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        labelsContainerView.backgroundColor = .black
        labelsContainerView.layer.cornerRadius = 3.0
        labelsContainerView.spacing = 6.0
        labelsContainerView.layer.masksToBounds = true
        labelsContainerView.layoutMargins = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        labelsContainerView.isLayoutMarginsRelativeArrangement = true

        microphoneImageView.image = StyleKitIcon.microphoneOff.makeImage(
            size: .tiny,
            color: IconColors.foregroundMicrophone
        )
        microphoneImageView.backgroundColor = IconColors.foregroundDefaultWhite
        microphoneImageView.contentMode = .center
        microphoneImageView.layer.cornerRadius = 3.0
        microphoneImageView.layer.masksToBounds = true

        blurView.alpha = 0
    }

    override func createConstraints() {
        super.createConstraints()

        labelsContainerView.setContentCompressionResistancePriority(.required, for: .horizontal)
        microphoneWidth = microphoneImageView.widthAnchor.constraint(equalToConstant: 22)
        NSLayoutConstraint.activate([
            labelsContainerView.centerXAnchor.constraint(equalTo: centerXAnchor).withPriority(.defaultLow),
            labelsContainerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            labelsContainerView.leadingAnchor.constraint(
                greaterThanOrEqualTo: microphoneImageView.trailingAnchor,
                constant: 2.0
            ),
            labelsContainerView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            microphoneImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            microphoneImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            microphoneImageView.heightAnchor.constraint(equalToConstant: 22),
            microphoneWidth!,
        ])
        updateMicrophoneView()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else {
            return
        }
        microphoneImageView.image = StyleKitIcon.microphoneOff.makeImage(
            size: .tiny,
            color: IconColors.foregroundMicrophone
        )
    }

    // MARK: Private

    private let nameLabel: UILabel
    private let connectingLabel: UILabel
    private let microphoneIconView = PulsingIconImageView()

    private let labelsContainerView = UIStackView(axis: .horizontal)
    private let microphoneImageView = UIImageView()
    private var microphoneWidth: NSLayoutConstraint?

    // MARK: - Methods to update the state of the microphone view

    private func updateMicrophoneView() {
        microphoneIconView.set(style: microphoneIconStyle)
        makeMicrophone(hidden: true)
        labelsContainerView.backgroundColor = .black
        nameLabel.textColor = .white

        switch microphoneIconStyle {
        case .unmutedPulsing:
            labelsContainerView.backgroundColor = UIColor.accent()
            nameLabel.textColor = SemanticColors.Label.textDefaultWhite

        case .muted:
            makeMicrophone(hidden: false)

        case .hidden, .unmuted:
            break
        }
    }

    private func makeMicrophone(hidden: Bool) {
        microphoneWidth?.constant = hidden ? 0 : 22
        microphoneImageView.isHidden = hidden
        setNeedsDisplay()
    }
}
