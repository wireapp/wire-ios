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
import WireAPI

@MainActor
struct GetBackendInfoView: View {

    @State 
    private var result: String?

    @State
    private var error: String?



    var body: some View {
        List {
            Button("Get backend info", action: execute)
            if let result {
                Text(result)
            }

            if let error {
                Text(error)
                    .foregroundStyle(.red)
            }
        }
    }

    private func execute() {
        Task {
            let builder = BackendInfoAPIBuilder(httpClient: HttpClient())
            let backendAPI = builder.makeAPI(for: .v0)

            do {
                let backendInfo = try await backendAPI.getBackendInfo()
                self.result = String(describing: backendInfo)
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

}

#Preview {
    GetBackendInfoView()
}
