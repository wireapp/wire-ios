//
//  AlertButtonAction.swift
//  KoiUI
//
//  Created by John Nguyen on 06.06.26.
//

import SwiftUI

/// Represents a button action in an alert.
///
/// Each `AlertButtonAction` defines a button's title, role, and callback action.
///
/// ## Button Roles
///
/// - `.confirm`: A standard action button (default)
/// - `.cancel`: A button that dismisses the alert without taking action
/// - `.destructive`: A button that performs a destructive action (e.g., delete)
///
/// ## Example
///
/// ```swift
/// let deleteAction = AlertButtonAction(
///     title: "Delete",
///     role: .destructive,
///     action: { deleteItem() }
/// )
///
/// let cancelAction = AlertButtonAction(
///     title: "Cancel",
///     role: .cancel
/// )
/// ```
public struct AlertButtonAction {

    /// The text displayed on the button.
    let title: String

    /// The semantic role of the button, affecting its styling and behavior.
    let role: ButtonRole

    /// The closure executed when the button is tapped.
    let action: () -> Void

    /// Creates a new button action.
    ///
    /// - Parameters:
    ///   - title: The text to display on the button.
    ///   - role: The semantic role of the button. Defaults to `.confirm`.
    ///   - action: The closure to execute when tapped. Defaults to an empty closure.
    public init(
        title: String,
        role: ButtonRole = .confirm,
        action: @escaping () -> Void = {}
    ) {
        self.title = title
        self.role = role
        self.action = action
    }

    /// A default OK button with confirm role.
    ///
    /// This is a convenience button that dismisses the alert without performing any action.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let alert = ErrorAlert(
    ///     title: "Success",
    ///     message: "Operation completed",
    ///     actions: [.ok]
    /// )
    /// ```
    public static let ok = AlertButtonAction(
        title: "OK",
        role: .confirm,
        action: {}
    )

}
