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

final class GroupDetailsSharedDriveCell: GroupDetailsDisclosureOptionsCell {

    typealias Strings = L10n.Localizable.GroupDetails.FileCollaborationCell

    override func setUp() {
        super.setUp()
        accessibilityIdentifier = "cell.groupdetails.fileCollaboration"
        title = Strings.title

        icon = UIImage(systemName: "rectangle.stack.fill")
        iconColor = SemanticColors.Icon.foregroundDefault
    }

    func configure(with conversation: GroupDetailsConversationType) {
        status = if DeveloperFlag.enableDrivePermissions.isOn {
            conversation.isSelfADriveEditor ? Strings.Subtitle.editorAccess : Strings.Subtitle.viewerAccess
        } else {
            Strings.subtitle
        }

        if !DeveloperFlag.enableDrivePermissions.isOn {
            accessory = nil
        }
    }

    override var isHighlighted: Bool {
        didSet {
            backgroundColor = ColorTheme.Backgrounds.surface
        }
    }

}
