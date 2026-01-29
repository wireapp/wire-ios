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

package import UniformTypeIdentifiers

package enum WireDriveFileCategory {

    case image
    case video
    case audio
    case document

<<<<<<< HEAD:WireMessaging/Sources/WireMessagingDomain/WireDrive/Model/WireDriveFileCategory.swift
    package init(_ fileType: UTType?) {
        guard let fileType else {
            self = .document
            return
        }

        if fileType.conforms(to: .image) {
            self = .image
        } else if fileType.conforms(to: .audio) { // `audio` must come before `.audiovisualContent`
            self = .audio
        } else if fileType.conforms(to: .audiovisualContent) {
            self = .video
        } else {
            self = .document
=======
    var body: some View {
        VStack(spacing: 0) {
            Divider()

            Button(action: action) {
                HStack(alignment: .center, spacing: 20) {
                    Image(systemName: "plus")

                    Text(L10n.Localizable.Conversation.WireCells.Files.List.createFolder)
                        .font(for: .body2)
                    Spacer()
                }
            }
            .tint(ColorTheme.Backgrounds.onSurface.color)
            .padding()
>>>>>>> e61291a897 (chore: cherry pick missing localizations from `develop` to `4.14` - WPB-22722 (#4224)):WireMessaging/Sources/WireMessagingUI/WireCells/Components/Files/CreateFolder/CreateFolderCTA.swift
        }
    }

}
