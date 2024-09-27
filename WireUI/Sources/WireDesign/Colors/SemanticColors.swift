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

// MARK: - SemanticColors

/// Naming convention:
///
/// The names of all SemanticColors should follow the format:
///
///  "<usage>.<context/role>.<state?>"
/// The last part is optional
public enum SemanticColors {
    public enum Switch {
        public static let backgroundOnStateEnabled = UIColor(light: .green600Light, dark: .green700Dark)
        public static let backgroundOffStateEnabled = UIColor(light: .gray70, dark: .gray70)
        public static let borderOnStateEnabled = UIColor(light: .green600Light, dark: .green500Dark)
        public static let borderOffStateEnabled = UIColor(light: .gray70, dark: .gray60)
    }

    public enum Label {
        public static let textDefault = UIColor(light: .black, dark: .white)
        public static let textDefaultWhite = UIColor(light: .white, dark: .black)
        public static let textWhite = UIColor(light: .white, dark: .white)
        public static let baseSecondaryText = UIColor(light: .gray70, dark: .gray60)

        public static let textMessageDate = UIColor(light: .gray70, dark: .gray60)
        public static let textSectionFooter = UIColor(light: .gray90, dark: .gray20)
        public static let textSectionHeader = UIColor(light: .gray70, dark: .gray50)
        public static let textCellSubtitle = UIColor(light: .gray90, dark: .white)
        public static let textNoResults = UIColor(light: .black, dark: .gray20)
        public static let textSettingsPasswordPlaceholder = UIColor(light: .gray70, dark: .gray60)
        public static let textLinkHeaderCellTitle = UIColor(light: .gray100, dark: .white)
        public static let textUserPropertyCellName = UIColor(light: .gray80, dark: .gray40)
        public static let textConversationQuestOptionInfo = UIColor(light: .gray90, dark: .gray20)
        public static let textConversationListItemSubtitleField = UIColor(light: .gray90, dark: .gray20)
        public static let textMessageDetails = UIColor(light: .gray70, dark: .gray40)
        public static let textCollectionSecondary = UIColor(light: .gray70, dark: .gray60)
        public static let textErrorDefault = UIColor(light: .red500Light, dark: .red500Dark)
        public static let textPasswordRulesCheck = UIColor(light: .gray80, dark: .gray20)
        public static let textTabBar = UIColor(light: .gray70, dark: .gray60)
        public static let textFieldFloatingLabel = UIColor(light: .gray80, dark: .gray50)
        public static let textSecurityEnabled = UIColor(light: .green500Light, dark: .green500Dark)

        public static let textReactionCounterSelected = UIColor(light: .blue500Light, dark: .blue500Dark)
        public static let textInactive = UIColor(light: .gray60, dark: .gray70)
        public static let textParticipantDisconnected = UIColor(light: .red300Light, dark: .red300Dark)

        // UserCell: e.g. "Paul Nagel (You)"
        public static let textYouSuffix = UIColor(light: .gray70, dark: .gray60)
        public static let textCertificateValid = UIColor(light: .green500Light, dark: .green500Dark)
        public static let textCertificateInvalid = UIColor(light: .red500Light, dark: .red500Dark)
        public static let textCertificateVerified = UIColor(light: .blue500Light, dark: .blue500Dark)
    }

    public enum SearchBar {
        public static let textInputView = UIColor(light: .black, dark: .white)
        public static let textInputViewPlaceholder = UIColor(light: .gray70, dark: .gray60)
        public static let backgroundInputView = UIColor(light: .white, dark: .black)
        public static let borderInputView = UIColor(light: .gray40, dark: .gray80)
        public static let backgroundButton = UIColor(light: .black, dark: .white)
    }

    public enum Icon {
        public static let backgroundDefault = UIColor(light: .gray70, dark: .gray60)
        public static let foregroundPlainCheckMark = UIColor(light: .black, dark: .white)
        public static let foregroundCheckMarkSelected = UIColor(light: .white, dark: .black)
        public static let foregroundPlaceholder = UIColor(light: .gray70, dark: .gray60)
        public static let borderCheckMark = UIColor(light: .gray80, dark: .gray60)
        public static let backgroundCheckMark = UIColor(light: .gray20, dark: .gray90)
        public static let backgroundCheckMarkSelected = UIColor(light: .blue500Light, dark: .blue500Dark)
        public static let backgroundSecurityEnabledCheckMark = UIColor(light: .green500Light, dark: .green500Dark)
        public static let foregroundDefault = UIColor(light: .gray90, dark: .white)
        public static let foregroundDefaultBlack = UIColor(light: .black, dark: .white)
        public static let foregroundDefaultWhite = UIColor(light: .white, dark: .black)
        public static let foregroundDefaultRed = UIColor(light: .red500Light, dark: .red500Dark)
        public static let foregroundPlainDownArrow = UIColor(light: .gray90, dark: .gray20)
        public static let backgroundJoinCall = UIColor(light: .green500Light, dark: .green500Dark)
        public static let foregroundAvailabilityAvailable = UIColor(light: .green500Light, dark: .green500Dark)
        public static let foregroundAvailabilityBusy = UIColor(light: .amber500Light, dark: .amber500Dark)
        public static let foregroundAvailabilityAway = UIColor(light: .red500Light, dark: .red500Dark)
        public static let backgroundPasswordRuleCheck = UIColor(light: .gray80, dark: .gray20)
        public static let backgroundMissedPhoneCall = UIColor(light: .red500Light, dark: .red500Dark)
        public static let foregroundMicrophone = UIColor(light: .red500Light, dark: .red500Dark)
        public static let emojiCategoryDefault = UIColor(light: .gray80, dark: .gray60)
        public static let emojiCategorySelected = UIColor(light: .black, dark: .white)

        // The init here is different because in light mode we would like the color of the border
        // to be clear. The initializer in all other cases in this file expects a type of ColorAsset
        // in both light and dark mode.
        public static let borderMutedNotifications = UIColor { traits in
            traits.userInterfaceStyle == .dark ? .init(resource: .gray70) : .clear
        }

        public static let foregroundElapsedTimeSelfDeletingMessage = UIColor(light: .gray50, dark: .gray80)
        public static let foregroundRemainingTimeSelfDeletingMessage = UIColor(light: .gray80, dark: .gray50)

        //  ThreeDotsLoadingView
        public static let foregroundLoadingDotInactive = UIColor(light: .gray50, dark: .gray80)
        public static let foregroundLoadingDotActive = UIColor(light: .gray80, dark: .gray50)

        // Audio Icon
        public static let foregroundAudio = UIColor(light: .black, dark: .white)

        // System Message Icon Colors
        public static let foregroundExclamationMarkInSystemMessage = UIColor(light: .red500Light, dark: .red500Dark)
        public static let foregroundCheckMarkInSystemMessage = UIColor(light: .green500Light, dark: .green500Dark)

        public static let backgroundLegalHold = UIColor(light: .red500Light, dark: .red500Dark)
    }

    public enum View {
        public static let backgroundDefault = UIColor(light: .gray20, dark: .gray100)
        public static let backgroundDefaultBlack = UIColor(light: .black, dark: .white)
        public static let backgroundDefaultWhite = UIColor(light: .white, dark: .black)
        public static let backgroundConversationView = UIColor(light: .gray10, dark: .gray95)
        public static let backgroundUserCell = UIColor(light: .white, dark: .gray95)
        public static let backgroundUserCellHightLighted = UIColor(light: .gray40, dark: .gray100)
        public static let backgroundSeparatorCell = UIColor(light: .gray40, dark: .gray90)
        public static let backgroundSeparatorEditView = UIColor(light: .gray60, dark: .gray70)
        public static let backgroundConversationList = UIColor(light: .gray20, dark: .gray100)
        public static let backgroundConversationListTableViewCell = UIColor(light: .white, dark: .gray95)
        public static let borderConversationListTableViewCell = UIColor(light: .gray40, dark: .gray90)
        public static let backgroundCollectionCell = UIColor(light: .white, dark: .gray90)
        public static let borderCollectionCell = UIColor(light: .gray30, dark: .gray80)
        public static let backgroundSecurityLevel = UIColor(light: .gray20, dark: .gray95)
        public static let borderSecurityEnabled = UIColor(light: .green500Light, dark: .green500Dark)
        public static let backgroundSecurityEnabled = UIColor(light: .green50Light, dark: .green900Dark)
        public static let backgroundSecurityDisabled = UIColor(light: .red600Light, dark: .red500Dark)
        public static let backgroundSeparatorConversationView = UIColor(light: .gray70, dark: .gray60)
        public static let backgroundReplyMessageViewHighlighted = UIColor(light: .gray40, dark: .gray80)
        public static let borderAvailabilityIcon = UIColor(light: .gray10, dark: .gray90)
        public static let borderCharacterInputField = UIColor(light: .gray80, dark: .gray40)
        public static let borderCharacterInputFieldEnabled = UIColor(light: .blue500Light, dark: .blue500Dark)
        public static let borderInputBar = UIColor(light: .gray40, dark: .gray100)
        public static let backgroundCallDragBarIndicator = UIColor(light: .gray70, dark: .gray70)
        public static let backgroundBlue = UIColor(light: .blue100Light, dark: .blue900Dark)
        public static let backgroundGreen = UIColor(light: .green100Light, dark: .green900Dark)
        public static let backgroundAmber = UIColor(light: .amber100Light, dark: .amber900Dark)
        public static let backgroundRed = UIColor(light: .red100Light, dark: .red900Dark)
        public static let backgroundPurple = UIColor(light: .purple100Light, dark: .purple900Dark)
        public static let backgroundTurqoise = UIColor(light: .turquoise100Light, dark: .turquoise900Dark)
        public static let backgroundCallOverlay = UIColor(light: .black, dark: .black)
        public static let backgroundCallTopOverlay = UIColor(light: .green500Light, dark: .green500Dark)

        // Mention
        public static let backgroundBlueUsernameMention = UIColor(light: .blue50Light, dark: .blue800Dark)
        public static let backgroundGreenUsernameMention = UIColor(light: .green50Light, dark: .green800Dark)
        public static let backgroundAmberUsernameMention = UIColor(light: .amber50Light, dark: .amber800Dark)
        public static let backgroundRedUsernameMention = UIColor(light: .red50Light, dark: .red800Dark)
        public static let backgroundPurpleUsernameMention = UIColor(light: .purple50Light, dark: .purple800Dark)
        public static let backgroundTurqoiseUsernameMention = UIColor(light: .turquoise50Light, dark: .turquoise800Dark)

        // AudioView
        public static let backgroundAudioViewOverlay = UIColor(light: .gray20, dark: .gray100)
        public static let backgroundAudioViewOverlayActive = UIColor(light: .white, dark: .gray95)
    }

    public enum TabBar {
        public static let backgroundSeperatorSelected = UIColor(light: .black, dark: .white)
        public static let backgroundSeparator = UIColor(light: .gray50, dark: .gray80)
    }

    public enum PageIndicator {
        public static let backgroundDefault = UIColor(light: .gray40, dark: .gray90)
    }

    public enum Button {
        public static let backgroundBarItem = UIColor(light: .white, dark: .gray90)
        public static let backgroundSecondaryEnabled = UIColor(light: .white, dark: .gray95)
        public static let backgroundSecondaryInConversationViewEnabled = UIColor(light: .white, dark: .gray100)
        public static let backgroundSecondaryHighlighted = UIColor(light: .white, dark: .gray80)
        public static let textSecondaryEnabled = UIColor(light: .black, dark: .white)
        public static let borderSecondaryEnabled = UIColor(light: .gray40, dark: .gray80)
        public static let borderSecondaryHighlighted = UIColor(light: .gray40, dark: .gray60)
        public static let backgroundPrimaryEnabled = UIColor(light: .blue500Light, dark: .blue500Dark)
        public static let backgroundPrimaryHighlighted = UIColor(light: .blue600Light, dark: .blue400Light)
        public static let backgroundPrimaryDisabled = UIColor(light: .gray50, dark: .gray70)
        public static let textPrimaryEnabled = UIColor(light: .white, dark: .black)
        public static let textPrimaryDisabled = UIColor(light: .gray80, dark: .black)
        public static let textEmptyEnabled = UIColor(light: .black, dark: .white)
        public static let textBottomBarNormal = UIColor(light: .gray90, dark: .gray50)
        public static let textBottomBarSelected = UIColor(light: .white, dark: .black)
        public static let textUnderlineEnabled = UIColor(light: .blue500Light, dark: .blue500Dark)
        public static let borderBarItem = UIColor(light: .gray40, dark: .gray100)
        public static let backgroundLikeEnabled = UIColor(light: .gray70, dark: .gray60)
        public static let backgroundLikeHighlighted = UIColor(light: .red500Light, dark: .red500Dark)
        public static let backgroundSendDisabled = UIColor(light: .gray70, dark: .gray70)
        public static let backgroundInputBarItemEnabled = UIColor(light: .white, dark: .gray90)
        public static let backgroundInputBarItemHighlighted = UIColor(light: .blue50Light, dark: .blue800Dark)
        public static let borderInputBarItemEnabled = UIColor(light: .gray40, dark: .gray100)
        public static let borderInputBarItemHighlighted = UIColor(light: .blue300Light, dark: .blue700Dark)
        public static let textInputBarItemEnabled = UIColor(light: .black, dark: .white)
        public static let textInputBarItemHighlighted = UIColor(light: .blue500Light, dark: .white)
        public static let reactionBorderSelected = UIColor(light: .blue300Light, dark: .blue700Dark)
        public static let reactionBackgroundSelected = UIColor(light: .blue50Light, dark: .blue800Dark)

        /// Calling buttons
        public static let backgroundCallingNormal = UIColor(light: .white, dark: .gray90)
        public static let backgroundCallingSelected = UIColor(light: .black, dark: .white)
        public static let backgroundCallingDisabled = UIColor(light: .gray20, dark: .gray95)

        public static let borderCallingNormal = UIColor(light: .gray40, dark: .gray100)
        public static let borderCallingSelected = UIColor(light: .black, dark: .white)
        public static let borderCallingDisabled = UIColor(light: .gray40, dark: .gray95)

        public static let iconCallingNormal = UIColor(light: .black, dark: .white)
        public static let iconCallingSelected = UIColor(light: .white, dark: .black)
        public static let iconCallingDisabled = UIColor(light: .gray60, dark: .gray70)

        public static let textCallingNormal = UIColor(light: .black, dark: .white)
        public static let textCallingDisabled = UIColor(light: .gray60, dark: .gray70)

        public static let backgroundPickUp = UIColor(light: .green500Light, dark: .green500Dark)
        public static let backgroundHangUp = UIColor(light: .red500Light, dark: .red500Dark)
        public static let textUnderlineEnabledDefault = UIColor(light: .black, dark: .white)

        // Reaction Button
        public static let backroundReactionNormal = UIColor(light: .white, dark: .black)
        public static let borderReactionNormal = UIColor(light: .gray50, dark: .gray80)
        public static let backgroundReactionSelected = UIColor(light: .blue50Light, dark: .blue900Dark)
        public static let borderReactionSelected = UIColor(light: .blue300Light, dark: .blue700Dark)

        /// Audio Buttons
        public static let backgroundAudioMessageOverlay = UIColor(light: .green500Light, dark: .green500Dark)
        public static let backgroundconfirmSendingAudioMessage = UIColor(light: .green500Light, dark: .green500Dark)

        // Scroll To Bottom Button
        public static let backgroundScrollToBottonEnabled = UIColor(light: .gray70, dark: .gray60)
    }

    public enum DrawingColors {
        public static let black = UIColor(light: .black, dark: .black)
        public static let white = UIColor(light: .white, dark: .white)
        public static let blue = UIColor(light: .blue500Light, dark: .blue500Light)
        public static let green = UIColor(light: .green500Light, dark: .green500Light)
        public static let yellow = UIColor(light: .amber500Dark, dark: .amber500Dark)
        public static let red = UIColor(light: .red500Light, dark: .red500Light)
        public static let orange = UIColor(red: 0.992, green: 0.514, blue: 0.071, alpha: 1)
        public static let purple = UIColor(light: .purple600Light, dark: .purple600Light)
        public static let brown = UIColor(light: .amber500Light, dark: .amber500Light)
        public static let turquoise = UIColor(light: .turquoise500Light, dark: .turquoise500Light)
        public static let sky = UIColor(light: .blue500Dark, dark: .blue500Dark)
        public static let lime = UIColor(light: .green500Dark, dark: .green500Dark)
        public static let cyan = UIColor(light: .turquoise500Dark, dark: .turquoise500Dark)
        public static let lilac = UIColor(light: .purple500Dark, dark: .purple500Dark)
        public static let coral = UIColor(light: .red500Dark, dark: .red500Dark)
        public static let pink = UIColor(red: 0.922, green: 0.137, blue: 0.608, alpha: 1)
        public static let chocolate = UIColor(red: 0.384, green: 0.184, blue: 0, alpha: 1)
        public static let gray = UIColor(light: .gray70, dark: .gray70)
    }

    public enum Accent {
        public static let blue = UIColor(light: .blue500Light, dark: .blue500Dark)
        public static let green = UIColor(light: .green500Light, dark: .green500Dark)
        public static let red = UIColor(light: .red500Light, dark: .red500Dark)
        public static let amber = UIColor(light: .amber500Light, dark: .amber500Dark)
        public static let turquoise = UIColor(light: .turquoise500Light, dark: .turquoise500Dark)
        public static let purple = UIColor(light: .purple500Light, dark: .purple500Dark)
    }
}

extension UIColor {
    fileprivate convenience init(light: ColorResource, dark: ColorResource) {
        self.init { traits in
            .init(resource: traits.userInterfaceStyle == .dark ? dark : light)
        }
    }
}
