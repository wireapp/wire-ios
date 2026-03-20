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
        static let headerIconSize: CGFloat = 16
    }

    @ScaledMetric private var readyToOpenIconPadding: CGFloat = 3.8
    @ScaledMetric private var scale: CGFloat = 1
    @Environment(\.wireAccentColor) private var wireAccentColor

    let headerIcon: Image
    let headerText: String
    let labelText: String
    let isDraftPreview: Bool
    let state: WireDriveFileUITracker.State

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

                if !isDraftPreview {
                    stateTextView()
                        .foregroundStyle(isError ? ColorTheme.Base.error.color : ColorTheme.Base.secondaryText.color)
                        .font(for: .subline1)
                        .lineLimit(1)
                }
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

    private var isError: Bool {
        switch state {
        case .failed:
            true
        default:
            false
        }
    }

    @ViewBuilder
    private func stateTextView() -> some View {
        switch state {
        case let .loaded(showReadyToOpen):
            if showReadyToOpen {
                Text(Strings.Files.readyToOpenAfterDownload)
            } else {
                EmptyView()
            }
        case .failed:
            Text(Strings.Files.downloadFailed)
        case .notLoaded:
            EmptyView()
        case .loading:
            Text(Strings.Files.tapToCancelDownload)
                .minimumScaleFactor(0.5)
        }
    }

    @ViewBuilder
    private func progressView(progress: Double) -> some View {
        ProgressView(value: progress)
            .progressViewStyle(.wireDriveAsset())
            .frame(height: Constants.headerIconSize)
    }

    @ViewBuilder
    private func stateIconView() -> some View {
        switch state {
        case let .loaded(showReadyToOpen):
            if showReadyToOpen {
                Image(systemName: "checkmark.circle")
                    .foregroundStyle(.blue)
                    .frame(width: Constants.headerIconSize * scale, height: Constants.headerIconSize * scale)
            } else {
                headerIcon
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: Constants.headerIconSize * scale)
            }
        case .failed:
            if isDraftPreview {
                Image(systemName: "exclamationmark.triangle")
                    .fontWeight(.semibold)
                    .font(.system(size: 14 * scale))
                    .foregroundStyle(Constants.errorColor)
            } else {
                headerIcon
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: Constants.headerIconSize * scale)
            }
        case .notLoaded:
            headerIcon
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: Constants.headerIconSize * scale)
        case let .loading(progress, _):
            progressView(progress: progress)
        }
    }

}

#Preview {
    WireDriveDocumentHeaderView(
        headerIcon: Image(WireDriveFileType.pdf.imageResource),
        headerText: "PDF (336 KB)",
        labelText: "CDR_20220120 Accessibility Review Reviewed Final Plus",
        isDraftPreview: false,
        state: .loading(progress: 0.7, isLargeFile: false)
    )
    .frame(width: 300, height: 74)
}
