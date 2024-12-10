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

/// A protocol for controlling the editing state of a view or controller.
///
/// This protocol is primarily intended for use in testing scenarios where
/// we need to programmatically set the editing state of a view controller
/// or similar object. It provides a clean, encapsulated way to modify
/// the editing state without exposing internal implementation details.
///
/// - Important: This protocol should not be used for production logic.
///   It's designed specifically to facilitate testing by allowing direct
///   control over the editing state in a way that may bypass normal
///   user interaction flows.
///
/// - Note: By using this protocol, we can write more robust tests that
///   don't rely on internal implementation details of the classes being tested.
///   This approach promotes better encapsulation and makes tests less brittle
///   in the face of implementation changes.
///
/// Current Usage:
/// - `ClientListViewController`: Used to set the editing state in snapshot tests
///   to verify the UI appearance in edit mode without triggering the full editing
///   flow that would normally be initiated by user interaction.
protocol EditingStateControllable {
    /// Sets the editing state of the conforming object.
    ///
    /// - Parameter isEditing: A boolean value where `true` puts the object
    ///   into editing mode, and `false` takes it out of editing mode.
    func setEditingState(_ isEditing: Bool)
}
