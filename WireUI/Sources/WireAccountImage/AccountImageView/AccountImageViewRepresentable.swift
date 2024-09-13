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

public struct AccountImageViewRepresentable: UIViewRepresentable {

    private let accountImage: UIImage
    private let availability: Availability?

    @Environment(\.accountImageBorderWidth) private var accountImageBorderWidth
    @Environment(\.accountImageViewBorderColor) private var accountImageViewBorderColor

    // MARK: - Life Cycle

    public init(
        accountImage: UIImage,
        availability: Availability?
    ) {
        self.accountImage = accountImage
        self.availability = availability
    }

    public func makeUIView(context: Context) -> AccountImageView {
        .init()
    }

    public func updateUIView(_ view: AccountImageView, context: Context) {
        view.accountImage = accountImage
        view.availability = availability
        view.accountImageBorderWidth = accountImageBorderWidth
        view.accountImageViewBorderColor = accountImageViewBorderColor
    }
}

extension AccountImageViewRepresentable {

    init(
        _ accountImage: UIImage,
        _ availability: Availability?
    ) {
        self.init(
            accountImage: accountImage,
            availability: availability
        )
    }
}

// MARK: - View Modifiers + Environment

extension View {
    func accountImageBorderWidth(_ accountImageBorderWidth: CGFloat) -> some View {
        modifier(AccountImageBorderWidthModifier(accountImageBorderWidth: accountImageBorderWidth))
    }
}

struct AccountImageBorderWidthModifier: ViewModifier {

    var accountImageBorderWidth: CGFloat

    func body(content: Content) -> some View {
        content
            .environment(\.accountImageBorderWidth, accountImageBorderWidth)
    }
}

private struct AccountImageBorderWidthKey: EnvironmentKey {
    static let defaultValue = AccountImageView.Defaults.accountImageBorderWidth
}

private extension EnvironmentValues {
    var accountImageBorderWidth: CGFloat {
        get { self[AccountImageBorderWidthKey.self] }
        set { self[AccountImageBorderWidthKey.self] = newValue }
    }
}

// MARK: -

extension View {
    func accountImageViewBorderColor(_ accountImageViewBorderColor: UIColor) -> some View {
        modifier(AccountImageViewBorderColorModifier(accountImageViewBorderColor: accountImageViewBorderColor))
    }
}

struct AccountImageViewBorderColorModifier: ViewModifier {

    var accountImageViewBorderColor: UIColor

    func body(content: Content) -> some View {
        content
            .environment(\.accountImageViewBorderColor, accountImageViewBorderColor)
    }
}

private struct AccountImageViewBorderColorKey: EnvironmentKey {
    static let defaultValue = AccountImageView.Defaults.accountImageViewBorderColor
}

private extension EnvironmentValues {
    var accountImageViewBorderColor: UIColor {
        get { self[AccountImageViewBorderColorKey.self] }
        set { self[AccountImageViewBorderColorKey.self] = newValue }
    }
}
