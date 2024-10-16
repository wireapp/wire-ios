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

public struct UserProfileView: View {

    @State private var selectedOption = 0

    public var body: some View {
        VStack {
            
            Picker("Options", selection: $selectedOption) {
                Text("Details")
                    .tag(0)
                Text("Devices")
                    .tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())

            switch selectedOption {
            case 0:
                let model = UserDetailsModel()
                UserDetailsView(model: model)
                    .padding()
            case 1:
                UserDevicesView()
                    .padding()
            default:
                EmptyView()
            }
            Spacer()
        }
        .padding()
    }
}

struct UserDetailsView: View {

    var model: UserDetailsModel

    var body: some View {
        VStack {
            Text(model.displayName)
            Text(model.username)
            Image(uiImage: model.accountImage ?? .init())
        }
    }
}

final class UserDetailsModel: ObservableObject {

    @Published private(set) var displayName = "John Doe"
    @Published private(set) var username = "@john_doe"
    @Published private(set) var accountImage = UIImage(systemName: "gearshape")
    @Published private(set) var accountRole = "admin"
}

public protocol UserDetailsProtocol {
    
}

struct UserDevicesView: View {
    var body: some View {
        Text("Hello World")
    }
}

#Preview {
    UserProfileView()
}
