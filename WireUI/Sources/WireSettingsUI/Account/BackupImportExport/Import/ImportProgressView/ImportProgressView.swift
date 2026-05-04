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
import WireDesign

struct ImportProgressView: View {

    var isLoadingFile = false
    var progressValues = (current: 0, total: 0)
    var cancelAction: () -> Void

    private typealias Strings = L10n.Localizable.ImportBackup
    private typealias Labels = L10n.Accessibility.ImportBackup

    var body: some View {
        NavigationStack {
            progressView
                .background(ColorTheme.Backgrounds.background.color)
                .navigationTitle(Strings.RestoringHistory.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(action: cancelAction) {
                            Text(Strings.Cancel.title)
                        }
                        .accessibilityLabel(Labels.Cancel.label)
                        .accessibilityIdentifier("cancel")
                    }
                }
        }
    }

    @ViewBuilder private var progressView: some View {
        if isLoadingFile {
            loadingFileView
        } else {
            loadingConversationsView
        }
    }

    @ViewBuilder private var loadingFileView: some View {
        VStack {
            Spacer()
            HStack {
                Text(Strings.LoadingBackup.message)
                Spacer()
            }
            .padding(.bottom)

            ProgressView()
                .scaleEffect(1.5)

            Spacer()
        }
        .padding()
    }

    @ViewBuilder private var loadingConversationsView: some View {
        let progressValue = if progressValues.current == 0 || progressValues.total == 0 {
            Float()
        } else {
            Float(progressValues.current) / Float(progressValues.total)
        }

        VStack {
            Spacer()
            HStack {
                Text(Strings.RestoringHistory.message)
                Spacer()
            }
            .padding(.bottom)

            HStack {
                Spacer()
                Text(progressValue.formatted(.percent.precision(.fractionLength(0))))
                    .font(.caption2)
                Spacer()
            }
            ProgressView(value: progressValue)

            Spacer()
        }
        .padding()
    }
}

#Preview("Loading file") {
    ImportProgressPreview(isLoadingFile: true)
}

#Preview("Loading conversations") {
    ImportProgressPreview(isLoadingFile: false)
}
