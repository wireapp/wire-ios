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

final class ConversationCreateFileManagementSectionController: ConversationCreateSectionController {

    typealias Cell = ConversationCreateFileManagementCell

    var toggleAction: ((Bool) -> Void)?

    override func prepareForUse(in collectionView: UICollectionView?) {
        super.prepareForUse(in: collectionView)
        collectionView.flatMap(Cell.register)
    }

}

extension ConversationCreateFileManagementSectionController {
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

    private func addAttributedText(
        to footer: SectionFooter
    ) {
        var fullText = L10n.Localizable.Conversation.Create.FileManagement.subtitle
        let learnMore = L10n.Localizable.Conversation.Create.FileManagement.learnMore
        fullText += " " + learnMore
        let attributedText = NSMutableAttributedString(string: fullText)
        let supportLink = "https://support.wire.com/hc/articles/32207749480477-Use-Wire-Drive-in-conversations"

        guard let learnMoreRange = fullText.range(of: "Learn more", options: .caseInsensitive) else {
            assertionFailure(
                "'Learn more' substring missing in \(L10n.Localizable.Conversation.Create.FileManagement.subtitle)"
            )
            return
        }
        
        let linkRange = NSRange(learnMoreRange, in: fullText)
        let fullRange = NSRange(location: 0, length: fullText.count)
        attributedText.addAttribute(.link, value: supportLink, range: linkRange)
        attributedText.addAttribute(.font, value: UIFont.font(for: .subline1), range: fullRange)
        attributedText.addAttribute(.foregroundColor, value: SemanticColors.Label.textSectionFooter, range: fullRange)
        
        footer.linkTextView.attributedText = attributedText
    }
}
