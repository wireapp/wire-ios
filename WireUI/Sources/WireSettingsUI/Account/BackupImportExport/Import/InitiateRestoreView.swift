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

struct InitiateRestoreView: View {

    @StateObject var viewModel: InitiateRestoreViewModel

    var onRestore: (_ url: URL) -> Void

    @State private var isFileImporterPresented = false

    var body: some View {
        Section(footer: Text(L10n.Localizable.Settings.RestoreFromBackup.description)) {
            Button(L10n.Localizable.Settings.RestoreFromBackup.action) {
                isFileImporterPresented = true
            }
            .fileImporter(
                isPresented: $isFileImporterPresented,
                allowedContentTypes: [.json]
            ) { result in
                switch result {
                case .success(let url):
                    let gotAccess = url.startAccessingSecurityScopedResource()
                    guard gotAccess else { return assertionFailure() } // TODO: also log before every assertionFailure
                    onRestore(url)
                    url.stopAccessingSecurityScopedResource()
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
        }
    }
}

#Preview {
    List {
        InitiateRestoreView(viewModel: .init()) { _ in }
    }
    .listStyle(.grouped)
}
