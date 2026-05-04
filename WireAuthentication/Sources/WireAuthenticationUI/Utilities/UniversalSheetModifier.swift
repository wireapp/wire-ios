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
import SwiftUIIntrospect
import WireDesign

/// This ViewModifier creates a custom overlay for iPad and fallback to .sheet on iPhone
/// - Note: On iPad, `sheet` modifier is presented as a page. PresentationDetents have no effect
struct UniversalSheetModifier<Item: Identifiable, SheetContent: View>: ViewModifier {

    @Binding var item: Item?
    var onDismiss: (() -> Void)?
    var content: (Item) -> SheetContent

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            if UIDevice.current.userInterfaceIdiom == .pad {

                content
                    .overlay {
                        if let item {
                            self.content(item)
                                .applyPreferredSize()
                        }
                    }

            } else {
                content.sheet(item: $item, onDismiss: onDismiss) { item in
                    self.content(item)
                        .applyPreferredSize()
                }
            }
        } else {
            // on iOS 17, we can't customize properly the sheet
            // so it will show as a page taking full space
            content.sheet(item: $item, onDismiss: onDismiss) { item in
                self.content(item)
                    .presentationDetents([.medium, .large])
            }
        }
    }
}

extension View {

    @ViewBuilder
    func sheetCornerRadius(_ radius: CGFloat, inNavigationStack: Bool) -> some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            modifier(SheetCornerRadiusModifier(radius: radius, inNavigationStack: inNavigationStack))
        } else {
            self
        }
    }

    public func universalSheet<Item>(
        item: Binding<Item?>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> some View
    ) -> some View where Item: Identifiable {
        modifier(UniversalSheetModifier(item: item, onDismiss: onDismiss, content: content))
    }
}

// MARK: - Specific helpers

/// ViewModifier to deal with cornerRadius and NavigationStack
private struct SheetCornerRadiusModifier: ViewModifier {
    let radius: CGFloat
    let inNavigationStack: Bool

    func body(content: Content) -> some View {
        if inNavigationStack {
            content
                .introspect(.navigationStack, on: .iOS(.v16, .v17, .v18)) { stack in
                    stack.topViewController?.view.backgroundColor = ColorTheme.Backgrounds.surface
                    // .cornerRadius from SwiftUI will mess with touch area with NavigationStack,
                    // when keyboard is active and after it's dismissed
                    stack.view?.layer.cornerRadius = radius
                }
        } else {
            content
                .background(ColorTheme.Backgrounds.surface.color)
                .cornerRadius(radius)
        }
    }
}
