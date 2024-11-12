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

final class EmptyConversationSearchResultsView: UIView {
    
    var newConversationAction: UIAction
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(newConversationAction: UIAction) {
        self.newConversationAction = newConversationAction
       
        super.init(frame: .zero)
        
        let titleLabel = DynamicFontLabel(
            text: L10n.Localizable.ConversationList.EmptyPlaceholder.Search.Subheadline.phone,
            style: .body1,
            color: ColorTheme.Base.secondaryText
        )
        
        let newConversationButton = DynamicFontButton(style: .body1)
        newConversationButton.setTitleColor(ColorTheme.Base.primary, for: .normal)
        
        let image = UIImage.imageForIcon(.plus, size: StyleKitIcon.Size.tiny.rawValue, color: ColorTheme.Backgrounds.background)
        let newIcon = createRoundIconImage(icon: image, iconSize: 10, backgroundColor: ColorTheme.Base.primary, imageSize: 20)
        
        let spacing: CGFloat = 10
        newConversationButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -spacing / 2, bottom: 0, right: spacing / 2)
        newConversationButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: spacing / 2, bottom: 0, right: -spacing / 2)
        
        newConversationButton.setImage(newIcon, for: .normal)
        newConversationButton.setBackgroundImageColor(ColorTheme.Backgrounds.background, for: .normal)
        newConversationButton.layer.cornerRadius = 18
        newConversationButton.layer.masksToBounds = true
        
        newConversationButton.addAction(newConversationAction, for: .touchUpInside)
        newConversationButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 42, bottom: 10, right: 42)
        newConversationButton.setTitle(L10n.Localizable.ConversationList.EmptyPlaceholder.Search.Button.phone, for: .normal)
        newConversationButton.accessibilityIdentifier = "new-conversation.button"
        
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        
        let stackView = UIStackView(arrangedSubviews: [titleLabel, newConversationButton])
        stackView.axis = .vertical
        stackView.spacing = 15
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        addSubview(stackView)
        NSLayoutConstraint.activate([
            
            stackView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            
            stackView.leadingAnchor.constraint(greaterThanOrEqualToSystemSpacingAfter: self.safeAreaLayoutGuide.leadingAnchor, multiplier: 1),
            stackView.topAnchor.constraint(greaterThanOrEqualToSystemSpacingBelow: self.safeAreaLayoutGuide.topAnchor, multiplier: 1),
            self.safeAreaLayoutGuide.trailingAnchor.constraint(greaterThanOrEqualToSystemSpacingAfter: stackView.trailingAnchor, multiplier: 1),
            self.safeAreaLayoutGuide.bottomAnchor.constraint(greaterThanOrEqualToSystemSpacingBelow: stackView.bottomAnchor, multiplier: 1),
            
            stackView.widthAnchor.constraint(lessThanOrEqualToConstant: 272)
        ])
        
    }
}

fileprivate func createRoundIconImage(icon: UIImage, iconSize: CGFloat, backgroundColor: UIColor, imageSize: CGFloat) -> UIImage? {
    // Create a UIView with a circular shape
    let view = UIView(frame: CGRect(x: 0, y: 0, width: imageSize, height: imageSize))
    view.backgroundColor = backgroundColor
    view.layer.cornerRadius = imageSize / 2
    view.clipsToBounds = true
    
    // Create an UIImageView for the icon and center it in the view
    let iconImageView = UIImageView(image: icon.withRenderingMode(.alwaysTemplate))
    iconImageView.contentMode = .scaleAspectFit
    iconImageView.frame = CGRect(x: (imageSize - iconSize) / 2, y: (imageSize - iconSize) / 2, width: iconSize, height: iconSize)
    view.addSubview(iconImageView)
    
    // Render the view into a UIImage
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, 0)
    view.layer.render(in: UIGraphicsGetCurrentContext()!)
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return image
}
