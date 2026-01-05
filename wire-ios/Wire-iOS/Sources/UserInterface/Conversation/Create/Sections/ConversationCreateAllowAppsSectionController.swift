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

import UIKit
import WireFoundation

final class ConversationCreateAllowAppsSectionController: ConversationCreateSectionController {

    typealias ToggleCell = ConversationCreateAllowAppsCell
    typealias FeatureDisabledCell = ConversationCreateAppsDisabledBannerCell

    var wireAccentColor = WireAccentColor.default
    var toggleAction: ((Bool) -> Void)?

    override func prepareForUse(in collectionView: UICollectionView?) {
        super.prepareForUse(in: collectionView)
        collectionView.flatMap(ToggleCell.register)
        collectionView.flatMap(FeatureDisabledCell.register)
        footerText = values.isAppsFeatureEnabled ? L10n.Localizable.Conversation.Create.Apps.subtitle : ""
    }

    /// Returns `1` for showing the toggle only and `2` for showing the disabled toggle with an info banner below.

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if values.areLegacyBotsAvailable, values.encryptionProtocol == .proteus {
            // Whenever the team was using old-style services (bots) we show the toggle but don't depend on the apps
            // feature flag. Hence we don't show the banner.
            1
        } else if values.isAppsFeatureEnabled {
            // no need to show a banner
            1
        } else {
            // disable toggle and show info banner
            2
        }
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {

        switch indexPath.row {

        case 0:
            let cell = collectionView.dequeueReusableCell(ofType: ToggleCell.self, for: indexPath)
            self.cell = cell
            cell.setUp()
            cell.configure(with: values)
            cell.action = toggleAction
            return cell

        default:
            let cell = collectionView.dequeueReusableCell(ofType: FeatureDisabledCell.self, for: indexPath)
            cell.wireAccentColor = wireAccentColor
            return cell
        }

    }

    override func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        if indexPath.row == 0 {
            return super.collectionView(collectionView, layout: collectionViewLayout, sizeForItemAt: indexPath)
        } else {
            let sizingCell = FeatureDisabledCell.sizingCell
            sizingCell.setNeedsLayout()
            sizingCell.layoutIfNeeded()
            let targetSize = CGSize(
                width: collectionView.bounds.width,
                height: UIView.layoutFittingCompressedSize.height
            )
            return sizingCell.systemLayoutSizeFitting(
                targetSize,
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .fittingSizeLevel
            )
        }
    }

}

// MARK: - Helper

private extension ConversationCreateAllowAppsSectionController.FeatureDisabledCell {
    static let sizingCell = ConversationCreateAllowAppsSectionController.FeatureDisabledCell()
}
