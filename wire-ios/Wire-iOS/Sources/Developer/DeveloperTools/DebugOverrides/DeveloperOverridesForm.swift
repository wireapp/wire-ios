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
import WireFoundation

struct DeveloperOverridesForm: View {

    @Environment(\.dismiss) private var dismiss

    @State private var buildNumber = DeveloperOverrides.buildNumber ?? ""
    @State private var obsoleteBackendEnv = DeveloperOverrides.obsoleteBackendEnv ?? ""
    @State private var obsoleteClientEnv = DeveloperOverrides.obsoleteClientEnv ?? ""

    @State private var isExitAlertPresented = false

    var body: some View {
        Form {
            Section("build number") {
                TextField("e.g. 12345", text: $buildNumber)
                Text("Use can set this to a blacklisted build number to simulate account blocking.")
                    .foregroundStyle(.secondary)
            }

            Section("Obselete backend") {
                TextField("e.g. staging", text: $obsoleteBackendEnv)
                Text(
                    "If an envirnoment name is specified, when resolving the api version then it will throw a 'obsolete backend' error."
                )
                .foregroundStyle(.secondary)
            }

            Section("Obsolete client") {
                TextField("e.g. anta.wire.link", text: $obsoleteClientEnv)
                Text(
                    "If an envirnoment name is specified, when resolving the api version then it will throw a 'obsolete client' error."
                )
                .foregroundStyle(.secondary)
            }
        }
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .toolbar {
            ToolbarItem {
                Button {
                    DeveloperOverrides.buildNumber = buildNumber.nonEmptyValue
                    DeveloperOverrides.obsoleteBackendEnv = obsoleteBackendEnv.nonEmptyValue
                    DeveloperOverrides.obsoleteClientEnv = obsoleteClientEnv.nonEmptyValue
                    isExitAlertPresented = true
                } label: {
                    Text("Submit")
                }
            }
        }
        .alert(
            "Relaunch app for changes to take effect",
            isPresented: $isExitAlertPresented,
            actions: { Button("OK", action: { exit(0) }) }
        )
        .padding()
    }

}

private extension String {

    var nonEmptyValue: String? {
        isEmpty ? nil : self
    }

}

#Preview {
    DeveloperOverridesForm()
}
