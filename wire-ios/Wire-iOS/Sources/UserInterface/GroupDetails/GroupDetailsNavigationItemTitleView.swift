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

final class GroupDetailsNavigationItemTitleView: UIView {

    var title: String {
        get { titleLabel.text ?? "" }
        set { titleLabel.text = newValue }
    }

    var verificationStatus: ConversationVerificationStatus {
        get { verificationStatusView.status }
        set {
            verificationStatusView.status = newValue
            verificationStatusView.isHidden = !newValue.isE2EICertified && !newValue.isProteusVerified
        }
    }

    private let stackView = UIStackView()
    private let titleLabel = DynamicFontLabel(style: .headline, color: SemanticColors.Label.textDefault)
    private let verificationStatusView = GroupConversationVerificationStatusView()

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
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            bottomAnchor.constraint(equalTo: stackView.bottomAnchor)
        ])

        stackView.axis = .vertical
        stackView.spacing = 6
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(verificationStatusView)

        titleLabel.textAlignment = .center
        verificationStatusView.isHidden = true
    }
}

// MARK: - Preview

private struct PreviewViewControllerRepresentable: UIViewControllerRepresentable {
    let title = "Details"
    let verificationStatus: ConversationVerificationStatus
    func makeUIViewController(context: Context) -> UINavigationController {
        .init(rootViewController: PreviewViewController())
    }
    func updateUIViewController(_ navigationController: UINavigationController, context: Context) {
        let viewController = navigationController.viewControllers[0] as! PreviewViewController
        viewController.navigationItemTitleView.title = title
        viewController.navigationItemTitleView.verificationStatus = verificationStatus
    }
}

private final class PreviewViewController: UIViewController {
    let navigationItemTitleView = GroupDetailsNavigationItemTitleView()
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItemTitleView.translatesAutoresizingMaskIntoConstraints = false
        navigationItem.titleView = navigationItemTitleView
    }
}

#Preview("neither nor") {
    PreviewViewControllerRepresentable(
        verificationStatus: .init(
            isE2EICertified: false,
            isProteusVerified: false
        )
    )
}

#Preview("only proteus") {
    PreviewViewControllerRepresentable(
        verificationStatus: .init(
            isE2EICertified: false,
            isProteusVerified: true
        )
    )
}

#Preview("only e2ei") {
    PreviewViewControllerRepresentable(
        verificationStatus: .init(
            isE2EICertified: true,
            isProteusVerified: false
        )
    )
}

#Preview("both") {
    PreviewViewControllerRepresentable(
        verificationStatus: .init(
            isE2EICertified: true,
            isProteusVerified: true
        )
    )
}
