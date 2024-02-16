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

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    private func setupSubviews() {
        let stackView = UIStackView(axis: .horizontal)
        // stackView.spacing =
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            topAnchor.constraint(equalTo: stackView.topAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        let label = UILabel()
        stackView.addArrangedSubview(label)

        let shieldImageView = UIImageView()
        stackView.addArrangedSubview(shieldImageView)
    }

    private func updateSubviews() {
        //
    }
}

private struct GroupConversationVerificationStatusViewRepresentable: UIViewRepresentable {

    @State var status = ConversationVerificationStatus()

    func makeUIView(context: Context) -> GroupConversationVerificationStatusView {.init() }
    func updateUIView(_ view: GroupConversationVerificationStatusView, context: Context) {
        view.status = status
    }
}

#Preview("neither nor") {
    GroupConversationVerificationStatusViewRepresentable(
        status: .init(
            e2eiCertificationStatus: false,
            proteusVerificationStatus: false
        )
    )
}

#Preview("verified") {
    GroupConversationVerificationStatusViewRepresentable(
        status: .init(
            e2eiCertificationStatus: false,
            proteusVerificationStatus: true
        )
    )
}

#Preview("certified") {
    GroupConversationVerificationStatusViewRepresentable(
        status: .init(
            e2eiCertificationStatus: true,
            proteusVerificationStatus: false
        )
    )
}

#Preview("both") {
    GroupConversationVerificationStatusViewRepresentable(
        status: .init(
            e2eiCertificationStatus: true,
            proteusVerificationStatus: true
        )
    )
}
