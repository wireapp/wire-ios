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

/// Custom `EnvironmentKey` to store a binding for the currently presented modal destination.
///
/// This allows SwiftUI views to access and modify the active modal (`modalDestination`)
/// without requiring direct dependency injection.
/// It provides a default value of `nil` to prevent crashes if accessed before being set.

private struct ModalDestinationKey: @preconcurrency EnvironmentKey {

    @MainActor
    static let defaultValue: Binding<ModalDestination?> = .constant(nil)

}

extension EnvironmentValues {

    /// Environment value for managing modal presentations dynamically.

    var modalDestination: Binding<ModalDestination?> {
        get { self[ModalDestinationKey.self] }
        set { self[ModalDestinationKey.self] = newValue }
    }

}
