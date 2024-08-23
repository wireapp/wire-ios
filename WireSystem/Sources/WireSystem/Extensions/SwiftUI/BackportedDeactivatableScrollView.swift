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

/// The `.scrollDisabled(_:)` view modifier is available only for iOS 16+.
/// Once the deployment target is equal or above iOS 16, this type can be removed.
public struct BackportedDeactivatableScrollView<Content>: View
where Content : View {

    private let axes: Axis.Set
    private let content: () -> Content

    public init(axes: Axis.Set, content: @escaping () -> Content) {
        self.axes = axes
        self.content = content
    }

    public var body: some View {

        if #available(iOS 16.0, *) {
            ScrollView(axes, content: content)
                .scrollDisabled(true)
        } else {
            // Fallback on earlier versions
        }
    }
}
