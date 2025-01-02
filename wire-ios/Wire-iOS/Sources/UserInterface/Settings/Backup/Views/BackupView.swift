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
import WireReusableUIComponents
import WireSettingsUI

public struct BackupView: View {
    @ObservedObject private var viewModel: BackupViewModel
    @State private var isSheetPresented: Bool = false

    public init(viewModel: BackupViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        List {
            ForEach(viewModel.sections) { section in
                Section(
                    footer: Text(section.type.footer)
                ) {
                    Button(action: {
                        print("Action for Section 1 triggered!")
                        withAnimation {
                            isSheetPresented = true
                        }
                    }) {
                        HStack {
                            Text(section.type.title)
                                .font(.textStyle(.body2))
                                .foregroundStyle(Color.primaryText)
                            Spacer()
                            Image(.chevronRight).foregroundStyle(Color.primary)
                        }
                    }
                    //                    .sheet(isPresented: $isSheetPresented) {
                    //                    }
//                    .presentationDragIndicator(.visible)
//                    .presentationDetents([.medium, .large])
                }
            }
        }
        .listStyle(.grouped)
        .listRowBackground(Color(ColorTheme.Backgrounds.background))
        .sheet(isPresented: $isSheetPresented) {
            //SetBackupPassword()
        }
    }
}

#Preview {
    BackupView(viewModel: BackupViewModel())
}

