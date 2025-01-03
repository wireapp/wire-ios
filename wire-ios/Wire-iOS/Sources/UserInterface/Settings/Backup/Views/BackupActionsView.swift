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

//import SwiftUI
//import WireDesign
//import WireReusableUIComponents
//import WireSettingsUI
//
//public struct BackupActionsView: View {
//    // TODO: or  @StateObject
//    @ObservedObject private var viewModel: BackupActionsViewModel
//    @State private var isBackupPresented: Bool = false
//    //TODO: use `isRestorePresented`
//    @State private var isRestorePresented: Bool = false
//
//    public init(viewModel: BackupActionsViewModel) {
//        self.viewModel = viewModel
//    }
//
//    public var body: some View {
//        List {
//            ForEach(viewModel.sections) { section in
//                Section(
//                    footer: Text(section.type.footer)
//                ) {
//                    Button(action: {
//                        switch section.type {
//                        case .backup:
//                            isRestorePresented = false
//                            isBackupPresented.toggle()
//                        case .restore:
//                            isBackupPresented = false
//                            isRestorePresented.toggle()
//                        }
//
//                    }) {
//                        HStack {
//                            Text(section.type.title)
//                                .font(.textStyle(.body2))
//                                .foregroundStyle(Color.primaryText)
//                            Spacer()
//                            Image(.chevronRight).foregroundStyle(Color.primary)
//                        }
//                    }
//                    .sheet(isPresented: $isBackupPresented) {
//                        NavigationStack {
//                            ExportBackup { password in
//                                viewModel.backupActiveAccount(password: password)
//                            }
//                        }
//                        .presentationDetents([.medium, .large])
//                    }
//                }
//            }
//        }
//        .listStyle(.grouped)
//        .listRowBackground(Color(ColorTheme.Backgrounds.background))
//    }
//}
//
//#Preview {
//    BackupActionsView(viewModel: BackupActionsViewModel(
//        backupSource: MockBackupSource(),
//        onSuccessHandler: {_,_  in},
//        onFailureHandler: {_ in}))
//}
//
//private class MockBackupSource: BackupSource {
//    func backupActiveAccount(password: String, completion: @escaping (Result<URL, any Error>) -> Void) {}
//    
//    func clearPreviousBackups() {}
//
//}
