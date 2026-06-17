//
//  ErrorAlert.swift
//  KoiDesign
//
//  Created by John Nguyen on 26.03.26.
//

import SwiftUI

/// A configurable alert model for presenting errors and confirmations.
///
/// `ErrorAlert` provides a declarative way to define alerts with custom titles,
/// messages, and actions. It works seamlessly with the `.errorAlert(_:)` view modifier
/// to present alerts in SwiftUI views.
///
/// ## Overview
///
/// Use `ErrorAlert` to create reusable alert configurations that can be presented
/// by binding to an optional state property. When the binding becomes non-nil,
/// the alert is automatically presented.
///
/// ## Example Usage
///
/// ```swift
/// struct ContentView: View {
///     @State private var errorAlert: ErrorAlert?
///
///     var body: some View {
///         Button("Show Error") {
///             errorAlert = ErrorAlert(
///                 title: "Network Error",
///                 message: "Unable to connect to the server."
///             )
///         }
///         .errorAlert($errorAlert)
///     }
/// }
/// ```
///
/// ## Topics
///
/// ### Creating an Alert
/// - ``init(title:message:actions:)``
///
/// ### Alert Properties
/// - ``title``
/// - ``message``
/// - ``actions``
///
/// ### Button Actions
/// - ``ButtonAction``
/// 
public struct ErrorAlert {

    /// The title of the alert.
    public let title: String
    
    /// An optional message providing additional context.
    public let message: String?
    
    /// The actions (buttons) to display in the alert.
    public let actions: [AlertButtonAction]

    /// Creates a new error alert.
    ///
    /// - Parameters:
    ///   - title: The title text displayed at the top of the alert.
    ///   - message: Optional descriptive text providing more context. Defaults to `nil`.
    ///   - actions: An array of button actions to display. Defaults to a single OK button.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Simple alert with default OK button
    /// let alert = ErrorAlert(title: "Error")
    ///
    /// // Alert with message
    /// let alert = ErrorAlert(
    ///     title: "Network Error",
    ///     message: "Please check your connection."
    /// )
    ///
    /// // Alert with custom actions
    /// let alert = ErrorAlert(
    ///     title: "Delete Item",
    ///     message: "This cannot be undone.",
    ///     actions: [
    ///         AlertButtonAction(
    ///             title: "Cancel",
    ///             role: .cancel
    ///         ),
    ///         AlertButtonAction(
    ///             title: "Delete",
    ///             role: .destructive,
    ///             action: { performDelete() }
    ///         )
    ///     ]
    /// )
    /// ```
    public init(
        title: String,
        message: String? = nil,
        actions: [AlertButtonAction] = [.ok]
    ) {
        self.title = title
        self.message = message
        self.actions = actions
    }

}

public extension ErrorAlert {

    static func generic(message: String) -> ErrorAlert {
        ErrorAlert(
            title: "Something went wrong",
            message: message
        )
    }

    static func debug(message: String) -> ErrorAlert {
        ErrorAlert(
            title: "⚠️ Debug alert!",
            message: message
        )
    }

}

public extension View {

    /// Presents an error alert when the binding to an optional `ErrorAlert` is non-nil.
    ///
    /// This modifier provides a declarative way to present alerts by binding to an
    /// optional `ErrorAlert`. When the binding value becomes non-nil, the alert is
    /// automatically presented. When the alert is dismissed, the binding is automatically
    /// set back to `nil`.
    ///
    /// - Parameter errorAlert: A binding to an optional `ErrorAlert`. When non-nil,
    ///   the alert is presented with the configured title, message, and actions.
    ///
    /// - Returns: A view that presents an alert when the binding is non-nil.
    ///
    /// ## Example
    ///
    /// ```swift
    /// struct ContentView: View {
    ///     @State private var errorAlert: ErrorAlert?
    ///
    ///     var body: some View {
    ///         VStack {
    ///             Button("Show Error") {
    ///                 errorAlert = ErrorAlert(
    ///                     title: "Error",
    ///                     message: "Something went wrong"
    ///                 )
    ///             }
    ///
    ///             Button("Confirm Action") {
    ///                 errorAlert = ErrorAlert(
    ///                     title: "Confirm",
    ///                     message: "Are you sure?",
    ///                     actions: [
    ///                         AlertButtonAction(
    ///                             title: "Cancel",
    ///                             role: .cancel
    ///                         ),
    ///                         AlertButtonAction(
    ///                             title: "Confirm",
    ///                             role: .destructive,
    ///                             action: { performAction() }
    ///                         )
    ///                     ]
    ///                 )
    ///             }
    ///         }
    ///         .errorAlert($errorAlert)
    ///     }
    ///
    ///     func performAction() {
    ///         // Action implementation
    ///     }
    /// }
    /// ```
    ///
    /// ## Topics
    ///
    /// ### Presenting Alerts
    /// - ``ErrorAlert``
    /// - ``ErrorAlert/ButtonAction``
    func errorAlert(_ errorAlert: Binding<ErrorAlert?>) -> some View {
        alert(
            errorAlert.wrappedValue?.title ?? "",
            isPresented: Binding(
                get: { errorAlert.wrappedValue != nil },
                set: { if !$0 { errorAlert.wrappedValue = nil } }
            )
        ) {
            if let alert = errorAlert.wrappedValue {
                ForEach(alert.actions.indices, id: \.self) { index in
                    Button(
                        alert.actions[index].title,
                        role: alert.actions[index].role
                    ) {
                        alert.actions[index].action()
                    }
                }
            }
        } message: {
            if let message = errorAlert.wrappedValue?.message {
                Text(message)
            }
        }
    }

}

#Preview("ErrorAlert Showcase") {
    @Previewable @State
    var errorAlert: ErrorAlert?

    ScrollView {
        VStack(spacing: 16) {
            Text("ErrorAlert Examples")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top)

            GroupBox("Basic Alerts") {
                VStack(spacing: 12) {
                    Button("Default Alert (title only)") {
                        errorAlert = ErrorAlert(title: "Error")
                    }
                    .buttonStyle(.bordered)

                    Button("Alert with Message") {
                        errorAlert = ErrorAlert(
                            title: "Network Error",
                            message: "Unable to connect to the server. Please check your internet connection."
                        )
                    }
                    .buttonStyle(.bordered)

                    Button("Alert with Long Message") {
                        errorAlert = ErrorAlert(
                            title: "Authentication Failed",
                            message: "Your session has expired. This could be due to inactivity or security reasons. Please log in again to continue using the app."
                        )
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.vertical, 8)
            }

            GroupBox("Custom Actions") {
                VStack(spacing: 12) {
                    Button("Single Custom Action") {
                        errorAlert = ErrorAlert(
                            title: "Confirm Delete",
                            message: "Are you sure you want to delete this item?",
                            actions: [
                                AlertButtonAction(
                                    title: "Delete",
                                    role: .destructive,
                                    action: { print("Item deleted") }
                                )
                            ]
                        )
                    }
                    .buttonStyle(.bordered)

                    Button("Multiple Actions (OK + Retry)") {
                        errorAlert = ErrorAlert(
                            title: "Operation Failed",
                            message: "The operation could not be completed.",
                            actions: [
                                .ok,
                                AlertButtonAction(
                                    title: "Retry",
                                    action: { print("Retrying...") }
                                )
                            ]
                        )
                    }
                    .buttonStyle(.bordered)

                    Button("Cancel + Destructive Action") {
                        errorAlert = ErrorAlert(
                            title: "Delete Account",
                            message: "This action cannot be undone. All your data will be permanently deleted.",
                            actions: [
                                AlertButtonAction(
                                    title: "Cancel",
                                    role: .cancel,
                                    action: { print("Cancelled") }
                                ),
                                AlertButtonAction(
                                    title: "Delete",
                                    role: .destructive,
                                    action: { print("Account deleted") }
                                )
                            ]
                        )
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.vertical, 8)
            }

            GroupBox("Edge Cases") {
                VStack(spacing: 12) {
                    Button("Empty Title") {
                        errorAlert = ErrorAlert(
                            title: "",
                            message: "Alert with no title"
                        )
                    }
                    .buttonStyle(.bordered)

                    Button("Three Actions") {
                        errorAlert = ErrorAlert(
                            title: "Choose Action",
                            message: "Select how you want to proceed.",
                            actions: [
                                AlertButtonAction(
                                    title: "Save",
                                    action: { print("Saved") }
                                ),
                                AlertButtonAction(
                                    title: "Discard",
                                    role: .destructive,
                                    action: { print("Discarded") }
                                ),
                                AlertButtonAction(
                                    title: "Cancel",
                                    role: .cancel,
                                    action: { print("Cancelled") }
                                )
                            ]
                        )
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.vertical, 8)
            }

            Text("Tap any button to see the alert")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom)
        }
        .padding()
    }
    .errorAlert($errorAlert)
}
