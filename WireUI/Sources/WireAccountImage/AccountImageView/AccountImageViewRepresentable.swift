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

    @Environment(\.availabilityIndicatorAvailableColor) private var availabilityIndicatorAvailableColor
    @Environment(\.availabilityIndicatorAwayColor) private var availabilityIndicatorAwayColor
    @Environment(\.availabilityIndicatorBusyColor) private var availabilityIndicatorBusyColor
    @Environment(\.availabilityIndicatorBackgroundViewColor) private var availabilityIndicatorBackgroundViewColor

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
    func accountImageBorderWidth(_ borderWidth: CGFloat) -> some View {
        modifier(AccountImageViewBorderWidthViewModifier(accountImageBorderWidth: borderWidth))
    }

    func accountImageViewBorderColor(_ borderColor: UIColor) -> some View {
        modifier(AccountImageViewBorderColorModifier(accountImageViewBorderColor: borderColor))
    }

    func availabilityIndicatorAvailableColor(_ availableColor: UIColor) -> some View {
        modifier(AvailabilityIndicatorViewAvailableColorViewModifier(availableColor: availableColor))
    }

    func availabilityIndicatorAwayColor(_ awayColor: UIColor) -> some View {
        modifier(AvailabilityIndicatorViewAwayColorViewModifier(awayColor: awayColor))
    }

    func availabilityIndicatorBusyColor(_ busyColor: UIColor) -> some View {
        modifier(AvailabilityIndicatorViewBusyColorViewModifier(availabilityIndicatorBusyColor: busyColor))
    }

    func availabilityIndicatorBackgroundViewColor(_ backgroundViewColor: UIColor) -> some View {
        modifier(AvailabilityIndicatorBackgroundColorViewModifier(availabilityIndicatorBackgroundViewColor: backgroundViewColor))
    }
}

private extension EnvironmentValues {
    var accountImageBorderWidth: CGFloat {
        get { self[AccountImageViewBorderWidthKey.self] }
        set { self[AccountImageViewBorderWidthKey.self] = newValue }
    }

    var accountImageViewBorderColor: UIColor {
        get { self[AccountImageViewBorderColorKey.self] }
        set { self[AccountImageViewBorderColorKey.self] = newValue }
    }

    var availabilityIndicatorAvailableColor: UIColor {
        get { self[AvailableColorKey.self] }
        set { self[AvailableColorKey.self] = newValue }
    }

    var availabilityIndicatorAwayColor: UIColor {
        get { self[AvailabilityIndicatorViewAwayColorKey.self] }
        set { self[AvailabilityIndicatorViewAwayColorKey.self] = newValue }
    }

    var availabilityIndicatorBusyColor: UIColor {
        get { self[AvailabilityIndicatorViewBusyColorKey.self] }
        set { self[AvailabilityIndicatorViewBusyColorKey.self] = newValue }
    }

    var availabilityIndicatorBackgroundViewColor: UIColor {
        get { self[AvailabilityIndicatorBackgroundViewColorKey.self] }
        set { self[AvailabilityIndicatorBackgroundViewColorKey.self] = newValue }
    }
}

struct AccountImageViewBorderWidthViewModifier: ViewModifier {
    var accountImageBorderWidth: CGFloat
    func body(content: Content) -> some View {
        content.environment(\.accountImageBorderWidth, accountImageBorderWidth)
    }
}

private struct AccountImageViewBorderWidthKey: EnvironmentKey {
    static let defaultValue = AccountImageView.Defaults.accountImageBorderWidth
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

struct AvailabilityIndicatorViewAvailableColorViewModifier: ViewModifier {
    var availableColor: UIColor
    func body(content: Content) -> some View {
        content.environment(\.availabilityIndicatorAvailableColor, availableColor)
    }
}

private struct AvailableColorKey: EnvironmentKey {
    static let defaultValue: UIColor = AvailabilityIndicatorView.Defaults.availableColor
}

struct AvailabilityIndicatorViewAwayColorViewModifier: ViewModifier {
    var awayColor: UIColor
    func body(content: Content) -> some View {
        content.environment(\.availabilityIndicatorAwayColor, awayColor)
    }
}

private struct AvailabilityIndicatorViewAwayColorKey: EnvironmentKey {
    static let defaultValue: UIColor = AvailabilityIndicatorView.Defaults.awayColor
}

struct AvailabilityIndicatorViewBusyColorViewModifier: ViewModifier {
    var availabilityIndicatorBusyColor: UIColor
    func body(content: Content) -> some View {
        content.environment(\.availabilityIndicatorBusyColor, availabilityIndicatorBusyColor)
    }
}

private struct AvailabilityIndicatorViewBusyColorKey: EnvironmentKey {
    static let defaultValue: UIColor = AvailabilityIndicatorView.Defaults.busyColor
}

struct AvailabilityIndicatorBackgroundColorViewModifier: ViewModifier {
    var availabilityIndicatorBackgroundViewColor: UIColor
    func body(content: Content) -> some View {
        content.environment(\.availabilityIndicatorBackgroundViewColor, availabilityIndicatorBackgroundViewColor)
    }
}

private struct AvailabilityIndicatorBackgroundViewColorKey: EnvironmentKey {
    static let defaultValue: UIColor = AvailabilityIndicatorView.Defaults.backgroundViewColor
}
