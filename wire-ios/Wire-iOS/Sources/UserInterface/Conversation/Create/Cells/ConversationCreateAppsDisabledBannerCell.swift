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
import WireCommonComponents
import WireDesign
import WireFoundation
import WireReusableUIComponents

final class ConversationCreateAppsDisabledBannerCell: UICollectionViewCell {

    var wireAccentColor = WireAccentColor.default {
        didSet {
            updateContent()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        updateContent()
    }

    private func updateContent() {
        contentConfiguration = UIHostingConfiguration {
            InfoBannerView(
                title: String(localized: "conversation.create.apps_disabled.title", bundle: .main),
                message: String(localized: "conversation.create.apps_disabled.message", bundle: .main)
            )
            .padding(16)
            .environment(\.wireAccentColor, wireAccentColor)
        }
    }

}
