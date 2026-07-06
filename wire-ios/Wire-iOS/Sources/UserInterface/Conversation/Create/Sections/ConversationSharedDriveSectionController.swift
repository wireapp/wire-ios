//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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
import WireUtilities

final class ConversationCreateSharedDriveSectionController: ConversationCreateSectionController {

    typealias Cell = ConversationCreateSharedDriveCell

    var toggleAction: ((Bool) -> Void)?

    override func prepareForUse(in collectionView: UICollectionView?) {
        super.prepareForUse(in: collectionView)
        collectionView.flatMap(Cell.register)
    }

}

extension ConversationCreateSharedDriveSectionController {
    override func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(ofType: Cell.self, for: indexPath)
        self.cell = cell
        cell.setUp()
        cell.configure(with: values)
        cell.action = toggleAction
        return cell
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        let sectionFooter = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: "SectionFooter",
            for: indexPath
        ) as! SectionFooter

        addAttributedText(to: sectionFooter)

        sectionFooter.linkTextView.isHidden = false

        return sectionFooter
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForFooterInSection section: Int
    ) -> CGSize {
        addAttributedText(to: footer)
        footer.size(fittingWidth: collectionView.bounds.width)
        return footer.bounds.size
    }

    private func addAttributedText(to footer: SectionFooter) {
        let subtitle = L10n.Localizable.Conversation.Create.FileManagement.subtitle
        let learnMore = L10n.Localizable.Conversation.Create.FileManagement.learnMore
        let supportLink = "https://support.wire.com/hc/articles/32207749480477-Use-Wire-Drive-in-conversations"

        let fullText = "\(subtitle) \(learnMore)"
        let attributedText = NSMutableAttributedString(string: fullText)

        guard let learnMoreRange = fullText.range(of: learnMore, options: .caseInsensitive) else {
            return assertionFailure("'Learn more' substring missing in subtitle")
        }

        // TODO: [WPB-25941] Remove developer flag when feature is complete
        if DeveloperFlag.enableDrivePermissions.isOn {
            attributedText.append(NSAttributedString(string: "\n\n"))
            attributedText.append(sharedDriveAccessAttributedString())
        }

        let fullRange = NSRange(location: 0, length: attributedText.length)

        attributedText.addAttribute(
            .link,
            value: supportLink,
            range: NSRange(learnMoreRange, in: fullText)
        )

        attributedText.addAttributes(
            [
                .font: UIFont.font(for: .subline1),
                .foregroundColor: SemanticColors.Label.textSectionFooter
            ],
            range: fullRange
        )

        footer.linkTextView.attributedText = attributedText
    }

    private func sharedDriveAccessAttributedString() -> NSAttributedString {
        let font = UIFont.font(for: .subline1)

        let image = UIImage(
            systemName: "lock.document",
            withConfiguration: UIImage.SymbolConfiguration(
                pointSize: font.pointSize + 1,
                weight: .regular
            )
        )?
            .withTintColor(
                SemanticColors.Label.textSectionFooter,
                renderingMode: .alwaysOriginal
            )

        let attachment = NSTextAttachment()
        attachment.image = image

        let result = NSMutableAttributedString(attachment: attachment)
        result.append(NSAttributedString(string: " "))
        result.append(
            NSAttributedString(
                string: L10n.Localizable.Conversation.Create.FileManagement.sharedDriveAccess
            )
        )

        return result
    }
}
