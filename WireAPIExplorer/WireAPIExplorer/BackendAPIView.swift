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
struct BackendAPIView: View {

    @State private var backendInfo: String = ""

    var body: some View {
        VStack {
            Button("Get backend info", action: executeRequest)
            Text(backendInfo)
        }
    }

    private func executeRequest() {
        Task {
            let builder = BackendInfoAPIBuilder(httpClient: HttpClient())
            let backendAPI = builder.makeAPI(for: .v0)

            do {
                let backendInfo = try await backendAPI.getBackendInfo()
                self.backendInfo = String(describing: backendInfo)
                print("result: \(backendInfo)")
            } catch {
                print("error: \(error)")
            }
        }
    }

}

#Preview {
    BackendAPIView().frame(width: 400, height: 200)
}
