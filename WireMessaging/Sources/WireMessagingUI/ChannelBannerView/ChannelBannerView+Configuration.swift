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

public extension ChannelBannerView {

    struct Configuration {

        public var title: String
        public var message: String
        public var mainButtonTitle: String
        public var mainButtonAction: () -> Void
        public var closeButton: CloseButton?

        public init(
            title: String,
            message: String,
            mainButtonTitle: String,
            mainButtonAction: @escaping () -> Void,
            closeButton: CloseButton? = nil
        ) {
            self.title = title
            self.message = message
            self.mainButtonTitle = mainButtonTitle
            self.mainButtonAction = mainButtonAction
            self.closeButton = closeButton
        }

    }

}

public extension ChannelBannerView.Configuration {

    struct CloseButton {

        public var accessibilityLabel: String
        public var action: () -> Void

        public init(accessibilityLabel: String, action: @escaping () -> Void) {
            self.accessibilityLabel = accessibilityLabel
            self.action = action
        }

    }

}
