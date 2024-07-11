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
import WireSyncEngine

struct ImportMessagesView: View {

    private enum ViewState {

        case loading
        case importButton

    }

    @State
    private var viewState = ViewState.importButton

    @Environment(\.dismiss)
    private var dismiss

    @State
    private var isFileImporterPresented = false

    @State
    private var error: ImportMessagesUseCaseError?

    @State
    private var isErrorAlertPresented = false

    var body: some View {
        Group {
            switch viewState {
            case .loading:
                ProgressView("Loading")

            case .importButton:
                VStack(alignment: .leading, spacing: 15) {
                    Text("Import messages")
                        .font(.largeTitle)

                    Text("Select a backup file to import your old messages into the app.")

                    Button {
                        isFileImporterPresented = true
                    } label: {
                        Text("Select backup")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding()
            }
        }
        .fileImporter(
            isPresented: $isFileImporterPresented,
            allowedContentTypes: [.zip]
        ) { result in
            switch result {
            case .success(let url):
                importMessages(from: url)

            case .failure(let error):
                print("failed to import file: ", error)
            }
        }
        .alert(isPresented: $isErrorAlertPresented, error: error) { _ in
            Text("Ok")
        } message: { error in
            Text(error.localizedDescription)
        }
    }

    private func importMessages(from url: URL) {
        guard let userSession = ZMUserSession.shared() else {
            return
        }

        let useCase = ImportMessagesUseCase(syncContext: userSession.syncContext)

        viewState = .loading

        Task.detached {
            do {
                try await useCase.invoke(backupURL: url)
                await MainActor.run {
                    dismiss()
                }
            } catch let importError as ImportMessagesUseCaseError {
                await MainActor.run {
                    viewState = .importButton
                    error = importError
                    isErrorAlertPresented = true
                }
            } catch {
                await MainActor.run {
                    viewState = .importButton
                    isErrorAlertPresented = true
                }
            }
        }
    }
}

#Preview {
    ImportMessagesView()
}
