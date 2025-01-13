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

import WireFoundation
import SwiftUI

@ViewBuilder @MainActor
func BackupActionsPreview() -> some View {
    BackupActionsView(viewModel: BackupActionsViewModel(
        backupSource: MockBackupSource(),
        backupResultHandler: BackupResultHandler(
            onSuccess: { _, _  in },
            onFailure: { _ in }
        ),
        passwordValidator: MockBackupPasswordValidator()
    ))
    .environment(\.wireTextStyleMapping, PreviewTextStyleMapping())
}

private class MockBackupSource: BackupSourceProtocol {
    func backupActiveAccount(password: String) throws -> URL {
        URL(fileURLWithPath: "path")
    }

    func clearPreviousBackups() {}
}

class MockBackupPasswordValidator: BackupPasswordValidatorProtocol {
    func isPasswordValid(_ password: String) -> Bool {
        true
    }

    var localizedRulesDescription: String {
        "Use at least 8 characters, with one lowercase letter, one capital letter, a number, and a special character."
    }
}

private func PreviewTextStyleMapping() -> WireTextStyleMapping {
    .init { _ in
        fatalError("not implemented for preview yet")
    } fontMapping: { textStyle in
        switch textStyle {
        case .body2:
            .callout.weight(.semibold)
        default:
            fatalError("not implemented for preview yet")
        }
    }
}
