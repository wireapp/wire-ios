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
import SafariServices

struct SFSafariView: UIViewControllerRepresentable {

    let url: URL

    func makeUIViewController(context: UIViewControllerRepresentableContext<Self>) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<SFSafariView>) {
    }
}

//var teamAccountCreationLink: URL? {
//        let baseURL = backendInfo.backendConfig.endpoints.teamsURL
//        if var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) {
//            components.queryItems = (components.queryItems ?? []) + [
//                URLQueryItem(name: "origin", value: "ios")
//            ]
//
//            return components.url
//        } else {
//            // can't generate url
//            return nil
//        }
//    }
//
//@Published var isCreateTeamAccountPresented = false
