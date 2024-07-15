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

import SwiftUI
import WireDesign

/// A view modifier that customizes the background style of a list, providing compatibility for different iOS versions.
struct ListBackgroundStyleModifier: ViewModifier {

    /// This method modifies the content view to apply a custom background style.
    ///
    /// - Parameter content: The content view to be modified.
    /// - Returns: A view with the customized background style applied.
    ///
    /// - Note:
    ///   - **iOS 16.0 and Later**: Starting from iOS 16.0, SwiftUI introduced
    ///     the `scrollContentBackground(_:)` method, which allows developers to
    ///     control the visibility of the scrollable content area’s background.
    ///     The `.hidden` parameter hides the default background, providing a
    ///     cleaner and more customizable look.
    ///   - **Earlier Versions**: In iOS versions before 16.0, the `scrollContentBackground(_:)`
    ///     method is not available. Therefore, we need an alternative way to
    ///     customize the background. In this case, we use the `background(_:)`
    ///     modifier to set a custom color defined by `SemanticColors.View.backgroundDefault`.
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content.scrollContentBackground(.hidden)
        } else {
            content.background(Color(SemanticColors.View.backgroundDefault))
        }
    }
}
