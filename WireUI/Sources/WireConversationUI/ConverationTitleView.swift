//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
import UIKit
import WireAccountImageUI
import WireDesign
import WireReusableUIComponents

public class ConversationTitleView: UIView {

    private let source: ConversationTitleSource

    private let accountImageView = AccountImageView()
    private let nameLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let dropdownImage = UIImageView(image: .dropdown)

    public init(source: ConversationTitleSource) {
        self.source = source
        super.init(frame: CGRect.zero)
        configureViews()
        configureLayout()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureViews() {
        nameLabel.font = FontSpec.normalSemiboldFont.font
        nameLabel.textColor = SemanticColors.Label.textDefault
        nameLabel.text = source.title

        subtitleLabel.font = FontSpec.smallBoldFont.font
        subtitleLabel.textColor = SemanticColors.Accent.blue
        subtitleLabel.text = source.subtitle

        accountImageView.availability = nil
        if let imageSource = source.accountImageSource {
            updateAvatar(source: imageSource, animated: false)
        }
        accountImageView.hideProfileNotificationsBadge = true
        accountImageView.isHidden = source.accountImageSource == nil
    }

    private func configureLayout() {

        let stackView = UIStackView.vertical()
        addSubview(stackView)
        stackView.alignment = .center

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.fitIn(view: self)

        let avatarAndNameStackView = UIStackView.horizontal(spacing: 5)
        avatarAndNameStackView.alignment = .center
        [accountImageView, nameLabel, dropdownImage]
            .forEach(avatarAndNameStackView.addArrangedSubview)

        var views: [UIView] = [avatarAndNameStackView]
        if source.subtitle != nil {
            views.append(subtitleLabel)
        }
        views.forEach(stackView.addArrangedSubview)

        accountImageView.constraintToSquare(sideLength: 32)
        dropdownImage.constraintToSquare(sideLength: 16)
    }
    
    public func updateSource(_ source: ConversationTitleSource) {
        if let imageSource = source.accountImageSource {
            updateAvatar(source: imageSource, animated: true)
        }
        accountImageView.isHidden = source.accountImageSource == nil
        nameLabel.text = source.title
        subtitleLabel.text = source.subtitle
    }
    
    private func updateAvatar(source: AccountImageSource, animated: Bool) {
        let updateBlock = {
            self.accountImageView.source = source
        }
        
        let animated = true

        if animated
//            ,
//           !ProcessInfo.processInfo.isRunningTests
        {
            UIView.transition(
                with: self,
                duration: 0.15,
                options: .transitionCrossDissolve,
                animations: updateBlock,
                completion: nil
            )
        } else {
            updateBlock()
        }
    }
}

@available(iOS 17, *)
#Preview("Account with Initials") {
    makeVC(source: ConversationTitleSource(
        accountImageSource: .text("DS"),
        title: "Wolfgang Wolf",
        subtitle: "FEDERATED"
    ))

}

@available(iOS 17, *)
#Preview("Account with Image") {
    makeVC(source: ConversationTitleSource(
        accountImageSource: .image(.checkmark),
        title: "Paul Nagel",
        subtitle: "GUEST"
    ))
}

@available(iOS 17, *)
#Preview("No subtitle") {
    makeVC(source: ConversationTitleSource(
        accountImageSource: .image(.checkmark),
        title: "Paul Nagel NagelNagelNagelNagelNagelNagel",
        subtitle: nil
    ))
}

@MainActor
private func makeVC(source: ConversationTitleSource) -> UIViewController {
    let vc = UIViewController()
    vc.navigationItem.titleView = ConversationTitleView(source: source)
    return UINavigationController(rootViewController: vc)
}
