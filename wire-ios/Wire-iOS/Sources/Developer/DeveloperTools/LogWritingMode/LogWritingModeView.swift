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
import WireCommonComponents

struct LogWritingModeView: View {

    @State private var selectedMode: LogWritingMode = LogWritingMode.current

    var body: some View {
        Form {
            Section {
                ForEach(LogWritingMode.allCases, id: \.self) { mode in
                    Button {
                        selectedMode = mode
                        LogWritingMode.current = mode
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(mode.title)
                                    .foregroundColor(.primary)
                                Text(mode.description)
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if selectedMode == mode {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }
            } header: {
                Text("Restart the app for changes to take effect.")
                    .textCase(.none)
            }
        }
        .navigationTitle("Log writing mode")
    }
}

// MARK: - Previews

struct LogWritingModeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            LogWritingModeView()
        }
    }
}
