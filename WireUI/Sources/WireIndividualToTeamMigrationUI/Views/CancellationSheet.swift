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
import WireDesign

extension View {
    func cancellationSheet(
        isPresented: Binding<Bool>,
        onContinue: @escaping @MainActor @Sendable () -> Void,
        onLeave: @escaping @MainActor @Sendable () -> Void
    ) -> some View {
        modifier(CancellationViewModifier(
            isPresented: isPresented,
            onContinue: onContinue,
            onLeave: onLeave
        ))
    }
}

struct CancellationViewModifier: ViewModifier {
    @Binding var isPresented: Bool

    let onContinue: @MainActor @Sendable () -> Void
    let onLeave: @MainActor @Sendable () -> Void

    func body(content: Content) -> some View {
        content
            .confirmationDialog(
                String.localized(key: "individualToTeam.cancellation.title", bundle: .module),
                isPresented: $isPresented,
                titleVisibility: .visible,
                actions: {
                    Button(
                        String.localized(key: "individualToTeam.cancellation.leave", bundle: .module),
                        role: .destructive,
                        action: onLeave
                    )
                    Button(
                        String.localized(key: "individualToTeam.cancellation.continue", bundle: .module),
                        role: .cancel,
                        action: onContinue
                    )
                    .foregroundStyle(.primary)
                    .wireTextStyle(.buttonBig)
                }
            )
    }
}
