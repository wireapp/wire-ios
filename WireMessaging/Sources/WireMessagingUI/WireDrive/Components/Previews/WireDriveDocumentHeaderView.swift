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
import WireFoundation
import WireMessagingDomain

private typealias Strings = L10n.Localizable.Conversation.WireCells

struct WireDriveDocumentHeaderView: View {
    enum Constants {
        static let errorColor = ColorTheme.Base.error.color
    }

    @ScaledMetric private var scale: CGFloat = 1
    @Environment(\.wireAccentColor) private var wireAccentColor

    let headerIcon: Image
    let headerText: String
    let labelText: String
    let progress: Double?
    let isError: Bool
    let showReadyToOpen: Bool

    var body: some View {
        header()
    }

    @ViewBuilder
    private func header() -> some View {
        VStack(alignment: .leading) {
            HStack(spacing: 4) {
                stateIconView()
                
                Text(headerText)
                    .foregroundStyle(ColorTheme.Base.secondaryText.color)
                    .font(for: .subline1)
                    .lineLimit(1)

                Spacer()
                
                stateTextView()
                    .foregroundStyle(isError ? ColorTheme.Base.error.color : ColorTheme.Base.secondaryText.color)
                    .font(for: .subline1)
                    .lineLimit(1)
            }
            .padding([.horizontal, .top], 8)

            Spacer(minLength: 0)

            Text(labelText)
                .foregroundStyle(ColorTheme.Backgrounds.onSurfaceVariant.color)
                .font(for: .h5)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding([.horizontal, .bottom], 8)
        }
    }
    
    @ViewBuilder
    private func stateTextView() -> some View {
        switch state {
        case .readyToOpen:
            Text(Strings.Files.readyToOpenAfterDownload)
        case .failed:
            Text(Strings.Files.downloadFailed)
        case .default:
            EmptyView()
        case .loading:
            Text(Strings.Files.tapToCancelDownload)
        }
    }

    @ViewBuilder
    private func stateIconView() -> some View {
        switch state {
        case .readyToOpen:
            Image(systemName: "checkmark.circle")
                .foregroundStyle(.blue)
        case .default, .failed:
            headerIcon
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 16 * scale)
        case .loading:
            ProgressView(value: progress, total: 1)
                .tint(Color.blue)
                .progressViewStyle(AssetProgressStyle(fillColor: ColorTheme.Base.primary(wireAccentColor).color))
        }
    }
    
    private enum State {
        case `default`
        case readyToOpen
        case failed
        case loading
    }
    
    private var state: State {
        if showReadyToOpen {
            .readyToOpen
        } else if isError {
            .failed
        } else if progress != nil {
            .loading
        } else {
            .default
        }
    }
}

#Preview {
    WireDriveDocumentHeaderView(
        headerIcon: Image(WireDriveFileType.pdf.imageResource),
        headerText: "PDF (336 KB)",
        labelText: "CDR_20220120 Accessibility Review Reviewed Final Plus",
        progress: 0.7,
        isError: false,
        showReadyToOpen: false
    )
    .frame(width: 300, height: 74)
}
