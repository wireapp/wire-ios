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

extension FontSpec {
    // MARK: - Small

    public static var smallFont: Self {
        self.init(.small, .none)
    }

    public static var smallLightFont: Self {
        self.init(.small, .light)
    }

    public static var smallRegularFont: Self {
        self.init(.small, .regular)
    }

    public static var smallMediumFont: Self {
        self.init(.small, .medium)
    }

    public static var smallSemiboldFont: Self {
        self.init(.small, .semibold)
    }

    public static var smallBoldFont: Self {
        self.init(.small, .bold)
    }

    // MARK: - Normal

    public static var normalFont: Self {
        self.init(.normal, .none)
    }

    public static var normalLightFont: Self {
        self.init(.normal, .light)
    }

    public static var normalRegularFont: Self {
        self.init(.normal, .regular)
    }

    public static var normalMediumFont: Self {
        self.init(.normal, .medium)
    }

    public static var normalSemiboldFont: Self {
        self.init(.normal, .semibold)
    }

    public static var normalBoldFont: Self {
        self.init(.normal, .bold)
    }

    public static var normalRegularFontWithInputTextStyle: Self {
        self.init(.normal, .regular, .inputText)
    }

    // MARK: - Medium

    public static var mediumFont: Self {
        self.init(.medium, .none)
    }

    public static var mediumSemiboldFont: Self {
        self.init(.medium, .semibold)
    }

    public static var mediumLightLargeTitleFont: Self {
        self.init(.medium, .light, .largeTitle)
    }

    public static var mediumRegularFont: Self {
        self.init(.medium, .regular)
    }

    public static var mediumSemiboldInputText: Self {
        self.init(.medium, .semibold, .inputText)
    }

    // MARK: - Large

    public static var largeFont: Self {
        self.init(.large, .none)
    }

    public static var largeThinFont: Self {
        self.init(.large, .thin)
    }

    public static var largeLightFont: Self {
        self.init(.large, .light)
    }

    public static var largeRegularFont: Self {
        self.init(.large, .regular)
    }

    public static var largeMediumFont: Self {
        self.init(.large, .medium)
    }

    public static var largeSemiboldFont: Self {
        self.init(.large, .semibold)
    }

    public static var largeLightWithTextStyleFont: Self {
        self.init(.large, .light, .largeTitle)
    }

    // Account
    public static var accountName: Self {
        self.init(.titleThree, .semibold)
    }

    public static var accountTeam: Self {
        self.init(.subHeadline, .regular)
    }

    // Navigation
    public static var headerSemiboldFont: Self {
        self.init(.header, .semibold)
    }

    public static var headerRegularFont: Self {
        self.init(.header, .regular)
    }

    public static var subheadlineFont: Self {
        self.init(.subHeadline, .regular)
    }

    // MARK: - Body

    public static var body: Self {
        self.init(.body, .regular)
    }

    // MARK: - Body Two

    public static var bodyTwoSemibold: Self {
        self.init(.bodyTwo, .semibold)
    }

    // MARK: - Button Small

    public static var buttonSmallBold: Self {
        self.init(.buttonSmall, .bold)
    }

    public static var buttonSmallSemibold: Self {
        self.init(.buttonSmall, .semibold)
    }

    // MARK: - Button Big

    public static var buttonBigSemibold: Self {
        self.init(.buttonBig, .semibold)
    }
}
