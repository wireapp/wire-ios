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

import Foundation

@MainActor
final class ImportBackupViewModel: ObservableObject {

    let importBackupUseCase: any ImportBackupUseCaseProtocol

    private var state: ImportBackupState? {
        didSet { updatePublishedProperties() }
    }

    @Published var isImportProgressPresented = false
    @Published var isEnterBackupPasswordPresented = false
    @Published var alertContent = ImportBackupAlertContent()
    @Published var isAlertPresented = false

    @Published private(set) var importProgress = Float()

    private var importTask: Task<Void, any Error>?

    init(importBackupUseCase: any ImportBackupUseCaseProtocol) {
        self.importBackupUseCase = importBackupUseCase
    }

    // MARK: - Methods

    func pickedBackupFile(result: Result<URL, any Error>) {
        do {
            switch result {

            case .failure(let error):
                print(error.localizedDescription)
                throw error

            case .success(let url):
                let gotAccess = url.startAccessingSecurityScopedResource()
                guard gotAccess else {
                    // TODO: throw error
                    return assertionFailure("TODO: handle/display error")
                }

                let fileManager = FileManager.default
                let tmpDirectory = try fileManager.url(
                    for: .itemReplacementDirectory,
                    in: .userDomainMask,
                    appropriateFor: url,
                    create: true
                )
                let copy = tmpDirectory.appendingPathComponent(url.lastPathComponent)
                try fileManager.copyItem(at: url, to: copy)
                url.stopAccessingSecurityScopedResource()

                importBackup(from: copy, password: "")
            }
        } catch {
            assertionFailure("TODO") // TODO: also log before every assertionFailure
            state = .restoreFailed(error)
        }
    }

    func importBackup(from url: URL) {
        importBackup(from: url, password: "")
    }

    func enterPassword(_ password: String) {
        guard case .requestingPassword(let url) = state else { return assertionFailure() }
        importBackup(from: url, password: password)
    }

    private func importBackup(from url: URL, password: String) {
        guard importTask == nil else { return assertionFailure() }

        importTask = Task {
            defer { importTask = nil }

            do {
                state = .importingBackup(progress: 0)
                for try await update in importBackupUseCase.invoke(url: url, password: password) {
                    switch update {
                    case .progress(let fraction):
                        state = .importingBackup(progress: fraction)
                    case .done:
                        state = .confirmation
                    }
                }
            } catch ImportBackupError.passwordRequired {
                state = .requestingPassword(url: url)
            } catch is CancellationError {
                state = nil
            } catch {
                state = .restoreFailed(error)
            }
        }
    }

    private func updatePublishedProperties() {

        isImportProgressPresented = switch state { case .importingBackup, .requestingPassword: true default: false }

        isEnterBackupPasswordPresented = if case .requestingPassword = state { true } else { false }

        // TODO: find better workaround for presentation issue
        let isAlertPresented = switch state { case .restoreFailed, .confirmation: true default: false }
        if isAlertPresented {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) { self.isAlertPresented = true }
        } else {
            self.isAlertPresented = false
        }

        importProgress = switch state { case .importingBackup(let progress): progress default: 0 }

    }
}
