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
import WireSyncEngine

/// Root of the guided bug-report flow, launched from the Developer Tools (shake) menu.
///
/// The flow is pushed onto the Developer Tools' ambient navigation stack, so each step
/// pushes the next one. The shared `BugReportFlowModel` is owned here and resolves the
/// active session/coordinator the same way the debug-report presenter does.
struct BugReportFlowView: View {

    @StateObject private var model: BugReportFlowModel

    /// - Parameter onClose: invoked to dismiss the whole Developer Tools menu (after send or cancel).
    init(onClose: @escaping () -> Void) {
        _model = StateObject(wrappedValue: Self.makeModel(onClose: onClose))
    }

    var body: some View {
        BugReportDescriptionStep(model: model)
    }

    private static func makeModel(onClose: @escaping () -> Void) -> BugReportFlowModel {
        let userSession = SessionManager.shared?.activeUserSession
        let model = BugReportFlowModel(
            userSession: userSession,
            mainCoordinator: ZClientViewController.shared?.mainCoordinator,
            selfUserID: userSession?.selfUser.remoteIdentifier
        )
        model.requestClose = onClose
        return model
    }
}

/// Shared chrome for a step: a progress indicator plus a Cancel button.
struct BugReportStepScaffold<Content: View>: View {

    let stepIndex: Int
    let title: String
    @ObservedObject var model: BugReportFlowModel
    @ViewBuilder var content: () -> Content

    private static var totalSteps: Int { 5 }

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.Localizable.BugReport.Step.progress(stepIndex, Self.totalSteps))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    ProgressView(value: Double(stepIndex), total: Double(Self.totalSteps))
                }
            }
            content()
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(L10n.Localizable.BugReport.cancel) { model.requestClose?() }
                    .accessibilityIdentifier("bugReport.cancel")
            }
        }
    }
}

/// A "Next" navigation button styled consistently across steps.
struct BugReportNextLink<Destination: View>: View {

    let isEnabled: Bool
    @ViewBuilder var destination: () -> Destination

    var body: some View {
        Section {
            NavigationLink {
                destination()
            } label: {
                Text(L10n.Localizable.BugReport.next)
                    .frame(maxWidth: .infinity)
                    .fontWeight(.semibold)
            }
            .disabled(!isEnabled)
            .accessibilityIdentifier("bugReport.next")
        }
    }
}
