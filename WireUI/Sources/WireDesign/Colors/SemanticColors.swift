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

/// Naming convention:
///
/// The names of all SemanticColors should follow the format:
///
///  "<usage>.<context/role>.<state?>"
/// The last part is optional
enum SemanticColors {

    enum Switch {
        static let backgroundOnStateEnabled = UIColor(light: .green600Light, dark: .green700Dark)
        static let backgroundOffStateEnabled = UIColor(light: .gray70, dark: .gray70)
        static let borderOnStateEnabled = UIColor(light: .green600Light, dark: .green500Dark)
        static let borderOffStateEnabled = UIColor(light: .gray70, dark: .gray60)
    }

    enum Label {
        static let textDefault = UIColor(light: .black, dark: .white)
        static let textDefaultWhite = UIColor(light: .white, dark: .black)
        static let textWhite = UIColor(light: .white, dark: .white)
        static let baseSecondaryText = UIColor(light: .gray70, dark: .gray60)

        static let textMessageDate = UIColor(light: .gray70, dark: .gray60)
        static let textSectionFooter = UIColor(light: .gray90, dark: .gray20)
        static let textSectionHeader = UIColor(light: .gray70, dark: .gray50)
        static let textCellSubtitle = UIColor(light: .gray90, dark: .white)
        static let textNoResults = UIColor(light: .black, dark: .gray20)
        static let textSettingsPasswordPlaceholder = UIColor(light: .gray70, dark: .gray60)
        static let textLinkHeaderCellTitle = UIColor(light: .gray100, dark: .white)
        static let textUserPropertyCellName = UIColor(light: .gray80, dark: .gray40)
        static let textConversationQuestOptionInfo = UIColor(light: .gray90, dark: .gray20)
        static let textConversationListItemSubtitleField = UIColor(light: .gray90, dark: .gray20)
        static let textMessageDetails = UIColor(light: .gray70, dark: .gray40)
        static let textCollectionSecondary = UIColor(light: .gray70, dark: .gray60)
        static let textErrorDefault = UIColor(light: .red500Light, dark: .red500Dark)
        static let textPasswordRulesCheck = UIColor(light: .gray80, dark: .gray20)
        static let textTabBar = UIColor(light: .gray70, dark: .gray60)
        static let textFieldFloatingLabel = UIColor(light: .gray80, dark: .gray50)
        static let textSecurityEnabled = UIColor(light: .green500Light, dark: .green500Dark)

        static let textReactionCounterSelected = UIColor(light: .blue500Light, dark: .blue500Dark)
        static let textInactive = UIColor(light: .gray60, dark: .gray70)
        static let textParticipantDisconnected = UIColor(light: .red300Light, dark: .red300Dark)

        // UserCell: e.g. "Paul Nagel (You)"
        static let textYouSuffix = UIColor(light: .gray70, dark: .gray60)
        static let textCertificateValid = UIColor(light: .green500Light, dark: .green500Dark)
        static let textCertificateInvalid = UIColor(light: .red500Light, dark: .red500Dark)
        static let textCertificateVerified = UIColor(light: .blue500Light, dark: .blue500Dark)
    }

    enum SearchBar {
        static let textInputView = UIColor(light: .black, dark: .white)
        static let textInputViewPlaceholder = UIColor(light: .gray70, dark: .gray60)
        static let backgroundInputView = UIColor(light: .white, dark: .black)
        static let borderInputView = UIColor(light: .gray40, dark: .gray80)
        static let backgroundButton = UIColor(light: .black, dark: .white)
    }

    enum Icon {
        static let backgroundDefault = UIColor(light: .gray70, dark: .gray60)
        static let foregroundPlainCheckMark = UIColor(light: .black, dark: .white)
        static let foregroundCheckMarkSelected = UIColor(light: .white, dark: .black)
        static let foregroundPlaceholder = UIColor(light: .gray70, dark: .gray60)
        static let borderCheckMark = UIColor(light: .gray80, dark: .gray60)
        static let backgroundCheckMark = UIColor(light: .gray20, dark: .gray90)
        static let backgroundCheckMarkSelected = UIColor(light: .blue500Light, dark: .blue500Dark)
        static let backgroundSecurityEnabledCheckMark = UIColor(light: .green500Light, dark: .green500Dark)
        static let foregroundDefault = UIColor(light: .gray90, dark: .white)
        static let foregroundDefaultBlack = UIColor(light: .black, dark: .white)
        static let foregroundDefaultWhite = UIColor(light: .white, dark: .black)
        static let foregroundDefaultRed = UIColor(light: .red500Light, dark: .red500Dark)
        static let foregroundPlainDownArrow = UIColor(light: .gray90, dark: .gray20)
        static let backgroundJoinCall = UIColor(light: .green500Light, dark: .green500Dark)
        static let foregroundAvailabilityAvailable = UIColor(light: .green500Light, dark: .green500Dark)
        static let foregroundAvailabilityBusy = UIColor(light: .amber500Light, dark: .amber500Dark)
        static let foregroundAvailabilityAway = UIColor(light: .red500Light, dark: .red500Dark)
        static let backgroundPasswordRuleCheck = UIColor(light: .gray80, dark: .gray20)
        static let backgroundMissedPhoneCall = UIColor(light: .red500Light, dark: .red500Dark)
        static let foregroundMicrophone = UIColor(light: .red500Light, dark: .red500Dark)
        static let emojiCategoryDefault = UIColor(light: .gray80, dark: .gray60)
        static let emojiCategorySelected = UIColor(light: .black, dark: .white)

        // The init here is different because in light mode we would like the color of the border
        // to be clear. The initializer in all other cases in this file expects a type of ColorAsset
        // in both light and dark mode.
        static let borderMutedNotifications = UIColor { traits in
            traits.userInterfaceStyle == .dark ? .init(resource: .gray70) : .clear
        }

        static let foregroundElapsedTimeSelfDeletingMessage = UIColor(light: .gray50, dark: .gray80)
        static let foregroundRemainingTimeSelfDeletingMessage = UIColor(light: .gray80, dark: .gray50)

        //  ThreeDotsLoadingView
        static let foregroundLoadingDotInactive = UIColor(light: .gray50, dark: .gray80)
        static let foregroundLoadingDotActive = UIColor(light: .gray80, dark: .gray50)

        // Audio Icon
        static let foregroundAudio = UIColor(light: .black, dark: .white)

        // System Message Icon Colors
        static let foregroundExclamationMarkInSystemMessage = UIColor(light: .red500Light, dark: .red500Dark)
        static let foregroundCheckMarkInSystemMessage = UIColor(light: .green500Light, dark: .green500Dark)

        static let backgroundLegalHold = UIColor(light: .red500Light, dark: .red500Dark)
    }

    enum View {
        static let backgroundDefault = UIColor(light: .gray20, dark: .gray100)
        static let backgroundDefaultBlack = UIColor(light: .black, dark: .white)
        static let backgroundDefaultWhite = UIColor(light: .white, dark: .black)
        static let backgroundConversationView = UIColor(light: .gray10, dark: .gray95)
        static let backgroundUserCell = UIColor(light: .white, dark: .gray95)
        static let backgroundUserCellHightLighted = UIColor(light: .gray40, dark: .gray100)
        static let backgroundSeparatorCell = UIColor(light: .gray40, dark: .gray90)
        static let backgroundSeparatorEditView = UIColor(light: .gray60, dark: .gray70)
        static let backgroundConversationList = UIColor(light: .gray20, dark: .gray100)
        static let backgroundConversationListTableViewCell = UIColor(light: .white, dark: .gray95)
        static let borderConversationListTableViewCell = UIColor(light: .gray40, dark: .gray90)
        static let backgroundCollectionCell = UIColor(light: .white, dark: .gray90)
        static let borderCollectionCell = UIColor(light: .gray30, dark: .gray80)
        static let backgroundSecurityLevel = UIColor(light: .gray20, dark: .gray95)
        static let borderSecurityEnabled = UIColor(light: .green500Light, dark: .green500Dark)
        static let backgroundSecurityEnabled = UIColor(light: .green50Light, dark: .green900Dark)
        static let backgroundSecurityDisabled = UIColor(light: .red600Light, dark: .red500Dark)
        static let backgroundSeparatorConversationView = UIColor(light: .gray70, dark: .gray60)
        static let backgroundReplyMessageViewHighlighted = UIColor(light: .gray40, dark: .gray80)
        static let borderAvailabilityIcon = UIColor(light: .gray10, dark: .gray90)
        static let borderCharacterInputField = UIColor(light: .gray80, dark: .gray40)
        static let borderCharacterInputFieldEnabled = UIColor(light: .blue500Light, dark: .blue500Dark)
        static let borderInputBar = UIColor(light: .gray40, dark: .gray100)
        static let backgroundCallDragBarIndicator = UIColor(light: .gray70, dark: .gray70)
        static let backgroundBlue = UIColor(light: .blue100Light, dark: .blue900Dark)
        static let backgroundGreen = UIColor(light: .green100Light, dark: .green900Dark)
        static let backgroundAmber = UIColor(light: .amber100Light, dark: .amber900Dark)
        static let backgroundRed = UIColor(light: .red100Light, dark: .red900Dark)
        static let backgroundPurple = UIColor(light: .purple100Light, dark: .purple900Dark)
        static let backgroundTurqoise = UIColor(light: .turquoise100Light, dark: .turquoise900Dark)
        static let backgroundCallOverlay = UIColor(light: .black, dark: .black)
        static let backgroundCallTopOverlay = UIColor(light: .green500Light, dark: .green500Dark)

        // Mention
        static let backgroundBlueUsernameMention = UIColor(light: .blue50Light, dark: .blue800Dark)
        static let backgroundGreenUsernameMention = UIColor(light: .green50Light, dark: .green800Dark)
        static let backgroundAmberUsernameMention = UIColor(light: .amber50Light, dark: .amber800Dark)
        static let backgroundRedUsernameMention = UIColor(light: .red50Light, dark: .red800Dark)
        static let backgroundPurpleUsernameMention = UIColor(light: .purple50Light, dark: .purple800Dark)
        static let backgroundTurqoiseUsernameMention = UIColor(light: .turquoise50Light, dark: .turquoise800Dark)

        // AudioView
        static let backgroundAudioViewOverlay = UIColor(light: .gray20, dark: .gray100)
        static let backgroundAudioViewOverlayActive = UIColor(light: .white, dark: .gray95)

    }

    enum TabBar {
        static let backgroundSeperatorSelected = UIColor(light: .black, dark: .white)
        static let backgroundSeparator = UIColor(light: .gray50, dark: .gray80)
    }

    enum PageIndicator {
        static let backgroundDefault = UIColor(light: .gray40, dark: .gray90)
    }

    enum Button {
        static let backgroundBarItem = UIColor(light: .white, dark: .gray90)
        static let backgroundSecondaryEnabled = UIColor(light: .white, dark: .gray95)
        static let backgroundSecondaryInConversationViewEnabled = UIColor(light: .white, dark: .gray100)
        static let backgroundSecondaryHighlighted = UIColor(light: .white, dark: .gray80)
        static let textSecondaryEnabled = UIColor(light: .black, dark: .white)
        static let borderSecondaryEnabled = UIColor(light: .gray40, dark: .gray80)
        static let borderSecondaryHighlighted = UIColor(light: .gray40, dark: .gray60)
        static let backgroundPrimaryEnabled = UIColor(light: .blue500Light, dark: .blue500Dark)
        static let backgroundPrimaryHighlighted = UIColor(light: .blue600Light, dark: .blue400Light)
        static let backgroundPrimaryDisabled = UIColor(light: .gray50, dark: .gray70)
        static let textPrimaryEnabled = UIColor(light: .white, dark: .black)
        static let textPrimaryDisabled = UIColor(light: .gray80, dark: .black)
        static let textEmptyEnabled = UIColor(light: .black, dark: .white)
        static let textBottomBarNormal = UIColor(light: .gray90, dark: .gray50)
        static let textBottomBarSelected = UIColor(light: .white, dark: .black)
        static let textUnderlineEnabled = UIColor(light: .blue500Light, dark: .blue500Dark)
        static let borderBarItem = UIColor(light: .gray40, dark: .gray100)
        static let backgroundLikeEnabled = UIColor(light: .gray70, dark: .gray60)
        static let backgroundLikeHighlighted = UIColor(light: .red500Light, dark: .red500Dark)
        static let backgroundSendDisabled = UIColor(light: .gray70, dark: .gray70)
        static let backgroundInputBarItemEnabled = UIColor(light: .white, dark: .gray90)
        static let backgroundInputBarItemHighlighted = UIColor(light: .blue50Light, dark: .blue800Dark)
        static let borderInputBarItemEnabled = UIColor(light: .gray40, dark: .gray100)
        static let borderInputBarItemHighlighted = UIColor(light: .blue300Light, dark: .blue700Dark)
        static let textInputBarItemEnabled = UIColor(light: .black, dark: .white)
        static let textInputBarItemHighlighted = UIColor(light: .blue500Light, dark: .white)
        static let reactionBorderSelected = UIColor(light: .blue300Light, dark: .blue700Dark)
        static let reactionBackgroundSelected = UIColor(light: .blue50Light, dark: .blue800Dark)

        /// Calling buttons
        static let backgroundCallingNormal = UIColor(light: .white, dark: .gray90)
        static let backgroundCallingSelected = UIColor(light: .black, dark: .white)
        static let backgroundCallingDisabled = UIColor(light: .gray20, dark: .gray95)

        static let borderCallingNormal = UIColor(light: .gray40, dark: .gray100)
        static let borderCallingSelected = UIColor(light: .black, dark: .white)
        static let borderCallingDisabled = UIColor(light: .gray40, dark: .gray95)

        static let iconCallingNormal = UIColor(light: .black, dark: .white)
        static let iconCallingSelected = UIColor(light: .white, dark: .black)
        static let iconCallingDisabled = UIColor(light: .gray60, dark: .gray70)

        static let textCallingNormal = UIColor(light: .black, dark: .white)
        static let textCallingDisabled = UIColor(light: .gray60, dark: .gray70)

        static let backgroundPickUp = UIColor(light: .green500Light, dark: .green500Dark)
        static let backgroundHangUp = UIColor(light: .red500Light, dark: .red500Dark)
        static let textUnderlineEnabledDefault = UIColor(light: .black, dark: .white)

        // Reaction Button
        static let backroundReactionNormal = UIColor(light: .white, dark: .black)
        static let borderReactionNormal = UIColor(light: .gray50, dark: .gray80)
        static let backgroundReactionSelected = UIColor(light: .blue50Light, dark: .blue900Dark)
        static let borderReactionSelected = UIColor(light: .blue300Light, dark: .blue700Dark)

        /// Audio Buttons
        static let backgroundAudioMessageOverlay = UIColor(light: .green500Light, dark: .green500Dark)
        static let backgroundconfirmSendingAudioMessage = UIColor(light: .green500Light, dark: .green500Dark)

        // Scroll To Bottom Button
        static let backgroundScrollToBottonEnabled = UIColor(light: .gray70, dark: .gray60)
    }

    enum DrawingColors {
        static let black = UIColor(light: .black, dark: .black)
        static let white = UIColor(light: .white, dark: .white)
        static let blue = UIColor(light: .blue500Light, dark: .blue500Light)
        static let green = UIColor(light: .green500Light, dark: .green500Light)
        static let yellow = UIColor(light: .amber500Dark, dark: .amber500Dark)
        static let red = UIColor(light: .red500Light, dark: .red500Light)
        static let orange = UIColor(red: 0.992, green: 0.514, blue: 0.071, alpha: 1)
        static let purple = UIColor(light: .purple600Light, dark: .purple600Light)
        static let brown = UIColor(light: .amber500Light, dark: .amber500Light)
        static let turquoise = UIColor(light: .turquoise500Light, dark: .turquoise500Light)
        static let sky = UIColor(light: .blue500Dark, dark: .blue500Dark)
        static let lime = UIColor(light: .green500Dark, dark: .green500Dark)
        static let cyan = UIColor(light: .turquoise500Dark, dark: .turquoise500Dark)
        static let lilac = UIColor(light: .purple500Dark, dark: .purple500Dark)
        static let coral = UIColor(light: .red500Dark, dark: .red500Dark)
        static let pink = UIColor(red: 0.922, green: 0.137, blue: 0.608, alpha: 1)
        static let chocolate = UIColor(red: 0.384, green: 0.184, blue: 0, alpha: 1)
        static let gray = UIColor(light: .gray70, dark: .gray70)
    }
}

extension UIColor {

    convenience init(light: ColorResource, dark: ColorResource) {
        self.init { traits in
            .init(resource: traits.userInterfaceStyle == .dark ? dark : light)
        }
    }
}
