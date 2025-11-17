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
import WireFoundation

struct SidebarAccountInfoView<AccountImageView: View, LegalHoldIndicatorView: View>: View {

    @Environment(\.sidebarAccountInfoViewDisplayNameColor) private var displayNameColor
    @Environment(\.sidebarAccountInfoViewUsernameColor) private var usernameColor

    // MARK: - Life Cycle

    let displayName: String
    let username: String
    let isE2EICertified: Bool
    let isVerified: Bool
    let isLegalHoldIndicatorVisible: Bool
    let accountImageView: () -> AccountImageView
    let legalHoldIndicatorView: () -> LegalHoldIndicatorView

    @State private var displayNameHeight: CGFloat = 0
    @State private var usernameHeight: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                accountImageView()
                    .frame(
                        width: displayNameHeight + usernameHeight,
                        height: displayNameHeight + usernameHeight
                    )
                ZStack {
                    determineLineHeights
                    displayNameAndUsername
                }
            }
            if isLegalHoldIndicatorVisible {
                HStack(spacing: 0) {
                    Rectangle()
                        .frame(width: displayNameHeight + usernameHeight, height: 0)
                        .padding(.trailing, 8)
                    legalHoldIndicatorView()
                        .frame(height: usernameHeight)
                        .padding(.trailing, 4)
                    Text("sidebar.legalHold.title", bundle: .module)
                        .wireTextStyle(.subline1)
                }
            }
        }
    }

    @ViewBuilder private var displayNameAndUsername: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .bottom, spacing: 4) {
                Text(displayName)
                    .wireTextStyle(.h3)
                    .foregroundStyle(displayNameColor)
                    .accessibilityLabel(L10n.Accessibility.Sidebar.Name.description)
                    .accessibilityValue(displayName)
                if isE2EICertified {
                    Image(.certificateValid)
                        .frame(height: usernameHeight)
                }
                if isVerified {
                    Image(.verified)
                        .frame(height: usernameHeight)
                }
            }
            Text(username)
                .wireTextStyle(.subline1)
                .foregroundStyle(usernameColor)
                .accessibilityLabel(L10n.Accessibility.Sidebar.Handle.description)
                .accessibilityValue(username)
        }
    }

    @ViewBuilder private var determineLineHeights: some View {
        VStack {
            Text("W")
                .wireTextStyle(.h3)
                .background(GeometryReader { geometryProxy in
                    Color.clear.preference(
                        key: DisplayNameHeightKey.self,
                        value: geometryProxy.size.height
                    )
                })
                .onPreferenceChange(DisplayNameHeightKey.self) { height in
                    displayNameHeight = height
                }
            Text("@")
                .wireTextStyle(.subline1)
                .background(GeometryReader { geometryProxy in
                    Color.clear.preference(
                        key: UsernameHeightKey.self,
                        value: geometryProxy.size.height
                    )
                })
                .onPreferenceChange(UsernameHeightKey.self) { height in
                    usernameHeight = height
                }
        }
        .lineLimit(1)
        .layoutPriority(-1)
        .opacity(0)
        .disabled(true)
    }
}

extension SidebarAccountInfoView {

    init(
        _ displayName: String,
        _ username: String,
        _ isE2EICertified: Bool,
        _ isVerified: Bool,
        _ isLegalHoldIndicatorVisible: Bool,
        _ accountImageView: @escaping () -> AccountImageView,
        _ legalHoldIndicatorView: @escaping () -> LegalHoldIndicatorView
    ) {
        self.init(
            displayName: displayName,
            username: username,
            isE2EICertified: isE2EICertified,
            isVerified: isE2EICertified,
            isLegalHoldIndicatorVisible: isLegalHoldIndicatorVisible,
            accountImageView: accountImageView,
            legalHoldIndicatorView: legalHoldIndicatorView
        )
    }
}

private struct DisplayNameHeightKey: PreferenceKey {
    static var defaultValue: CGFloat { 0 }
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct UsernameHeightKey: PreferenceKey {
    static var defaultValue: CGFloat { 0 }
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - View Modifiers + Environment

extension View {
    func sidebarAccountInfoViewDisplayNameColor(_ displayNameColor: Color) -> some View {
        modifier(
            SidebarAccountInfoViewDisplayNameColorViewModifier(sidebarAccountInfoViewDisplayNameColor: displayNameColor)
        )
    }

    func sidebarAccountInfoViewUsernameColor(_ usernameColor: Color) -> some View {
        modifier(SidebarAccountInfoViewUsernameColorViewModifier(sidebarAccountInfoViewUsernameColor: usernameColor))
    }
}

private extension EnvironmentValues {
    var sidebarAccountInfoViewDisplayNameColor: Color {
        get { self[SidebarAccountInfoViewDisplayNameColorKey.self] }
        set { self[SidebarAccountInfoViewDisplayNameColorKey.self] = newValue }
    }

    var sidebarAccountInfoViewUsernameColor: Color {
        get { self[SidebarAccountInfoViewUsernameColorKey.self] }
        set { self[SidebarAccountInfoViewUsernameColorKey.self] = newValue }
    }
}

struct SidebarAccountInfoViewDisplayNameColorViewModifier: ViewModifier {
    var sidebarAccountInfoViewDisplayNameColor: Color
    func body(content: Content) -> some View {
        content
            .environment(\.sidebarAccountInfoViewDisplayNameColor, sidebarAccountInfoViewDisplayNameColor)
    }
}

private struct SidebarAccountInfoViewDisplayNameColorKey: EnvironmentKey {
    static let defaultValue = Color.primary
}

struct SidebarAccountInfoViewUsernameColorViewModifier: ViewModifier {
    var sidebarAccountInfoViewUsernameColor: Color
    func body(content: Content) -> some View {
        content
            .environment(\.sidebarAccountInfoViewUsernameColor, sidebarAccountInfoViewUsernameColor)
    }
}

private struct SidebarAccountInfoViewUsernameColorKey: EnvironmentKey {
    static let defaultValue = Color.primary.opacity(0.7)
}

// MARK: - Previews

#Preview {
    SidebarAccountInfoPreview()
}
