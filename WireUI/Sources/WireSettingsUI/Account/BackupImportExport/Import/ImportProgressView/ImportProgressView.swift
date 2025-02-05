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
import WireDesign

struct ImportProgressView: View {

    var progressValue = Float()
    var cancelAction: () -> Void

    var body: some View {
        NavigationStack {
            progressView
                .background(Color(uiColor: ColorTheme.Backgrounds.background))
                .navigationTitle(Text(L10n.Localizable.ImportBackup.RestoringHistory.title))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(action: cancelAction) {
                            Text(L10n.Localizable.ImportBackup.Cancel.title)
                        }
                        .foregroundStyle(Color(uiColor: ColorTheme.Base.primary))
                        .accessibilityLabel(Text(L10n.Accessibility.ImportBackup.Cancel.label))
                        .accessibilityIdentifier("cancel")
                    }
                }
        }
    }

    @ViewBuilder private var progressView: some View {
        VStack {
            Spacer()
            HStack {
                Text(L10n.Localizable.ImportBackup.RestoringHistory.message)
                Spacer()
            }
            .padding(.bottom)
            HStack {
                Spacer()
                Text("\(Int(progressValue * 100))%")
                    .font(.caption2)
                Spacer()
            }
            ProgressView(value: progressValue)
            Spacer()
        }
        .padding()
    }
}

#Preview {
    ImportProgressPreview()
}
