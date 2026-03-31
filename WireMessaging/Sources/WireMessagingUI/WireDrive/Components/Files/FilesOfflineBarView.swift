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

struct FilesOfflineBarView: View {
    var body: some View {
        VStack {
            Text(
                L10n.Localizable.General.NoInternet.title.uppercased()
            )
            .font(for: .subline2)
            .foregroundColor(.white) // TODO: [WPB-24475] use proper color
            .frame(maxWidth: .infinity)
            .frame(height: 25)
            .background {
                // TODO: [WPB-24475] use proper color
                Color(
                    red: 254.0 / 255.0,
                    green: 191.0 / 255.0,
                    blue: 2.0 / 255.0,
                    opacity: 1
                )
            }
            .cornerRadius(6)
            
            //TODO: Olga said this design will probably change. don't localise yet.
            Label {
                Text("You can only see downloaded files in the offline mode.") //TODO: localize
                    //.multilineTextAlignment(.center)
            } icon: {
                Image(systemName: "wifi.slash")
            }
        }
        .padding(.horizontal, 16)
    }
}

#Preview {
    FilesOfflineBarView()
}
