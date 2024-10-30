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

    private let source: AccountImageSource
    private let availability: Availability?

    @Environment(\.accountImageBorderWidth) private var accountImageBorderWidth
    @Environment(\.accountImageBorderColor) private var accountImageBorderColor

    @Environment(\.availabilityIndicatorAvailableColor) private var availabilityIndicatorAvailableColor
    @Environment(\.availabilityIndicatorAwayColor) private var availabilityIndicatorAwayColor
    @Environment(\.availabilityIndicatorBusyColor) private var availabilityIndicatorBusyColor
    @Environment(\.availabilityIndicatorBackgroundViewColor) private var availabilityIndicatorBackgroundViewColor

    // MARK: - Life Cycle

    public init(
        source: AccountImageSource,
        availability: Availability?
    ) {
        self.source = source
        self.availability = availability
    }

    public func makeUIView(context: Context) -> AccountImageView {
        .init()
    }

    public func updateUIView(_ view: AccountImageView, context: Context) {
        view.source = source
        view.availability = availability
        view.imageBorderWidth = accountImageBorderWidth
        view.imageBorderColor = accountImageBorderColor

        view.availabilityIndicatorView.availableColor = availabilityIndicatorAvailableColor
        view.availabilityIndicatorView.awayColor = availabilityIndicatorAwayColor
        view.availabilityIndicatorView.busyColor = availabilityIndicatorBusyColor
        view.availabilityIndicatorView.backgroundViewColor = availabilityIndicatorBackgroundViewColor
    }
}

extension AccountImageViewRepresentable {

    init(
        _ source: AccountImageSource,
        _ availability: Availability?
    ) {
        self.init(
            source: source,
            availability: availability
        )
    }
}

// MARK: - View Modifiers + Environment

public extension View {
    func accountImageBorderWidth(_ borderWidth: CGFloat) -> some View {
        modifier(AccountImageViewBorderWidthViewModifier(accountImageBorderWidth: borderWidth))
    }

    func accountImageViewBorderColor(_ borderColor: UIColor) -> some View {
        modifier(AccountImageBorderColorModifier(accountImageViewBorderColor: borderColor))
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
        get { self[AccountImageBorderWidthKey.self] }
        set { self[AccountImageBorderWidthKey.self] = newValue }
    }

    var accountImageBorderColor: UIColor {
        get { self[AccountImageBorderColorKey.self] }
        set { self[AccountImageBorderColorKey.self] = newValue }
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

private struct AccountImageBorderWidthKey: EnvironmentKey {
    static let defaultValue = AccountImageView.Defaults.imageViewBorderWidth
}

struct AccountImageBorderColorModifier: ViewModifier {
    var accountImageViewBorderColor: UIColor
    func body(content: Content) -> some View {
        content
            .environment(\.accountImageBorderColor, accountImageViewBorderColor)
    }
}

private struct AccountImageBorderColorKey: EnvironmentKey {
    static let defaultValue = AccountImageView.Defaults.imageViewBorderColor
}

struct AvailabilityIndicatorViewAvailableColorViewModifier: ViewModifier {
    var availableColor: UIColor
    func body(content: Content) -> some View {
        content.environment(\.availabilityIndicatorAvailableColor, availableColor)
    }
}

private struct AvailableColorKey: EnvironmentKey {
    static let defaultValue = AvailabilityIndicatorView.Defaults.availableColor
}

struct AvailabilityIndicatorViewAwayColorViewModifier: ViewModifier {
    var awayColor: UIColor
    func body(content: Content) -> some View {
        content.environment(\.availabilityIndicatorAwayColor, awayColor)
    }
}

private struct AvailabilityIndicatorViewAwayColorKey: EnvironmentKey {
    static let defaultValue = AvailabilityIndicatorView.Defaults.awayColor
}

struct AvailabilityIndicatorViewBusyColorViewModifier: ViewModifier {
    var availabilityIndicatorBusyColor: UIColor
    func body(content: Content) -> some View {
        content.environment(\.availabilityIndicatorBusyColor, availabilityIndicatorBusyColor)
    }
}

private struct AvailabilityIndicatorViewBusyColorKey: EnvironmentKey {
    static let defaultValue = AvailabilityIndicatorView.Defaults.busyColor
}

struct AvailabilityIndicatorBackgroundColorViewModifier: ViewModifier {
    var availabilityIndicatorBackgroundViewColor: UIColor
    func body(content: Content) -> some View {
        content.environment(\.availabilityIndicatorBackgroundViewColor, availabilityIndicatorBackgroundViewColor)
    }
}

private struct AvailabilityIndicatorBackgroundViewColorKey: EnvironmentKey {
    static let defaultValue = AvailabilityIndicatorView.Defaults.backgroundViewColor
}
