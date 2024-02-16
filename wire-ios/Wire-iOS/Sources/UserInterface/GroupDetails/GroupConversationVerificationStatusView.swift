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

import SwiftUI
import WireDataModel

final class GroupConversationVerificationStatusView: UIView {

    var status = ConversationVerificationStatus() {
        didSet { updateSubviews() }
    }

    private let label = UILabel()
    private let shieldImageView = UIImageView()
    private let stackView = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    private func setupSubviews() {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            topAnchor.constraint(equalTo: stackView.topAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        stackView.axis = .horizontal
        stackView.spacing = 6
        stackView.addArrangedSubview(label)
        stackView.addArrangedSubview(shieldImageView)

        // TODO [WPB-765]: use predefined font
        label.font = .systemFont(ofSize: 12)
        shieldImageView.contentMode = .center
    }

    private func updateSubviews() {
        if status.isE2EICertified {
            label.text = L10n.Localizable.GroupDetails.ConversationVerificationStatus.e2ei
            label.textColor = SemanticColors.DrawingColors.green
            shieldImageView.image = .init(resource: .certificateValid)
        } else if status.isProteusVerified {
            label.text = L10n.Localizable.GroupDetails.ConversationVerificationStatus.proteus
            label.textColor = SemanticColors.DrawingColors.blue
            shieldImageView.image = .init(resource: .verifiedShield)
        } else {
            label.text = ""
            shieldImageView.image = nil
        }

        label.isHidden = label.text == ""
        shieldImageView.isHidden = label.isHidden
    }
}

private struct GroupConversationVerificationStatusViewRepresentable: UIViewRepresentable {

    @State var status = ConversationVerificationStatus()

    func makeUIView(context: Context) -> GroupConversationVerificationStatusView {
        let view = GroupConversationVerificationStatusView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.status = status
        return view
    }

    func updateUIView(_ view: GroupConversationVerificationStatusView, context: Context) {
        view.status = status
    }
}

#Preview {
    VStack(alignment: .leading) {
        Divider()
        Text("neither nor:").font(.callout)
        GroupConversationVerificationStatusViewRepresentable(
            status: .init(
                isE2EICertified: false,
                isProteusVerified: false
            )
        )
        Divider()
        Text("verified:").font(.callout)
        GroupConversationVerificationStatusViewRepresentable(
            status: .init(
                isE2EICertified: false,
                isProteusVerified: true
            )
        )
        Divider()
        Text("certified:").font(.callout)
        GroupConversationVerificationStatusViewRepresentable(
            status: .init(
                isE2EICertified: true,
                isProteusVerified: false
            )
        )
        Divider()
        Text("both:").font(.callout)
        GroupConversationVerificationStatusViewRepresentable(
            status: .init(
                isE2EICertified: true,
                isProteusVerified: true
            )
        )
        Spacer()
    }.padding()
}
