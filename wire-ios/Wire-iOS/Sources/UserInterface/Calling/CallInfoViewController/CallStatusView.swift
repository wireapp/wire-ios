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

// MARK: - CallStatusViewState

enum CallStatusViewState: Equatable {
    case none
    case connecting
    case ringingIncoming(name: String?) // Caller name + call type "XYZ is calling..."
    case ringingOutgoing // "Ringing..."
    case established(duration: TimeInterval) // Call duration in seconds "04:18"
    case reconnecting // "Reconnecting..."
    case terminating // "Ending call..."
}

// MARK: - CallStatusView

final class CallStatusView: UIView {
    // MARK: Lifecycle

    init(configuration: CallStatusViewInputType) {
        self.configuration = configuration
        super.init(frame: .zero)
        setupViews()
        createConstraints()
        updateConfiguration()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    var configuration: CallStatusViewInputType {
        didSet {
            updateConfiguration()
        }
    }

    // MARK: Private

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let bitrateLabel = BitRateLabel(fontSpec: .smallSemiboldFont, color: SemanticColors.Label.textDefaultWhite)
    private let stackView = UIStackView(axis: .vertical)

    private func setupViews() {
        [stackView, bitrateLabel].forEach(addSubview)
        stackView.distribution = .fill
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        bitrateLabel.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = 12
        accessibilityIdentifier = "CallStatusLabel"
        [titleLabel, subtitleLabel].forEach(stackView.addArrangedSubview)
        for item in [titleLabel, subtitleLabel, bitrateLabel] {
            item.textAlignment = .center
        }

        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.font = .systemFont(ofSize: 20, weight: UIFont.Weight.semibold)
        subtitleLabel.font = FontSpec(.normal, .semibold).font
        subtitleLabel.alpha = 0.64

        bitrateLabel.font = FontSpec(.small, .semibold).font
        bitrateLabel.alpha = 0.64
        bitrateLabel.accessibilityIdentifier = "bitrate-indicator"
        bitrateLabel.isHidden = true
    }

    private func createConstraints() {
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            bitrateLabel.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 16),
            bitrateLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            bitrateLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            bitrateLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    private func updateConfiguration() {
        titleLabel.text = configuration.title
        subtitleLabel.text = configuration.displayString
        bitrateLabel.isHidden = !configuration.shouldShowBitrateLabel
        bitrateLabel.bitRateStatus = BitRateStatus(configuration.isConstantBitRate)

        for item in [titleLabel, subtitleLabel, bitrateLabel] {
            item.textColor = SemanticColors.Label.textDefault
        }
    }
}

// MARK: - Helper

private let callDurationFormatter: DateComponentsFormatter = {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.minute, .second]
    formatter.zeroFormattingBehavior = .pad
    return formatter
}()

extension CallStatusViewInputType {
    var displayString: String {
        switch state {
        case .none: ""
        case .connecting: L10n.Localizable.Call.Status.connecting
        case let .ringingIncoming(name: name?): L10n.Localizable.Call.Status.Incoming.user(name)
        case .ringingIncoming(name: nil): L10n.Localizable.Call.Status.incoming
        case .ringingOutgoing: L10n.Localizable.Call.Status.outgoing
        case let .established(duration: duration): callDurationFormatter.string(from: duration) ?? ""
        case .reconnecting: L10n.Localizable.Call.Status.reconnecting
        case .terminating: L10n.Localizable.Call.Status.terminating
        }
    }
}
