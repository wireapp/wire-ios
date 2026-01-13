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
import SwiftUI

struct PreferredSizeKey: PreferenceKey, Sendable {
    static let defaultValue: CGSize? = .none

    static func reduce(value: inout CGSize?, nextValue: () -> CGSize?) {
        let next = nextValue()

        if next != nil {
            value = next
        }
    }
}

/// Set PreferredSize of child to parent view
struct PreferredSizeModifier: ViewModifier {

    @State var size: CGSize = .init(width: 390, height: 420)

    func body(content: Content) -> some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            content
                .frame(width: size.width, height: size.height)
                .onPreferenceChange(PreferredSizeKey.self, perform: setSize)
        } else {
            content
                .onPreferenceChange(PreferredSizeKey.self, perform: setSize)
                .presentationDetents([.height(size.height)])
        }
    }

    private func setSize(value: CGSize?) {
        if let value {
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.4)) {
                    size.height = min(value.height, maxSize.height)
                    size.width = min(value.width, maxSize.width)
                }
            }
        }
    }

    var maxSize: CGSize {
        let ratio = 0.75
        let size = UIScreen.main.bounds.size
        return .init(width: size.width * ratio, height: size.height * ratio)
    }
}

extension View {

    /// Calculates the size of a view and communicate it to parents in order to set container size
    /// - Parameter navigationBarHidden: whether the navigationBar of the NavigationStack is visible or not
    /// - Returns: a View
    @ViewBuilder
    func setPreferredSize(navigationBarHidden: Bool = true) -> some View {
        background(
            GeometryReader { proxy in
                Color.clear
                    .preference(
                        key: PreferredSizeKey.self,
                        value: CGSize(
                            width: proxy.size.width,
                            height: navigationBarHidden ? proxy.size.height : proxy.size.height + 44
                        )
                    )
            }
        )
    }

    @ViewBuilder
    func applyPreferredSize() -> some View {
        modifier(PreferredSizeModifier())
    }
}
