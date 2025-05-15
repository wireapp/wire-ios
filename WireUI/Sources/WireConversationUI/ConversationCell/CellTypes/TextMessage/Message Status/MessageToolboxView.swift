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
import WireDesign

struct MessageToolboxView: View {

    var detailsText: String
    var editedString: String?
    var deliveryStatus: MessageToolboxState?
    var deliveryIcon: Image?
    var countdownText: String?

    //    var onOpenDetails: (() -> Void)?
    
    var font: Font = FontSpec.smallRegularFont.swiftUIFont
    var textColor: Color = SemanticColors.Label.textMessageDetails.color

    var body: some View {
        HStack(spacing: 3) {

            detailsLabel(detailsText)
//                .onTapGesture {
//                    viewModel.openDetails()
//                }

            if let editedString {
                separator
                editedLabel(editedString)
            }
            
            if let deliveryStatus {
                if !detailsText.isEmpty {
                    separator
                }
                statusContainerView(deliveryStatus)
            }

            if let countdown = countdownText {
                separator
                // TODO: circle view with progress
                countDownLabel(countdown)
            }
        }
    }
    
    @ViewBuilder private func editedLabel(_ text: String) -> some View {
        Text(text)
            .lineLimit(1)
            .truncationMode(.middle)
            .font(font)
            .foregroundColor(textColor)
            .accessibilityIdentifier("Edited")
            .accessibilityElement()
            .layoutPriority(1)
    }
    
    @ViewBuilder private func statusLabel(_ text: String) -> some View {
        Text(text)
            .lineLimit(1)
            .truncationMode(.middle)
            .font(font)
            .foregroundColor(textColor)
            .accessibilityIdentifier("DeliveryStatus")
            .accessibilityElement()
            .layoutPriority(1)
    }

    @ViewBuilder private func detailsLabel(_ text: String) -> some View {
        Text(text)
            .lineLimit(1)
            .truncationMode(.middle)
            .font(font)
            .foregroundColor(textColor)
            .accessibilityIdentifier("Details")
            .accessibilityElement()
            .layoutPriority(1) // equivalent to high hugging and compression
    }

    @ViewBuilder private var separator: some View {
        Text("･")
            .font(.body)
            .foregroundColor(SemanticColors.Label.baseSecondaryText.color)
            .lineLimit(1)
            .truncationMode(.tail)
            .layoutPriority(1)
            .accessibilityHidden(true)
    }
    
    @ViewBuilder
    private func countDownLabel(_ text: String) ->  some View {
        Text(text)
            .lineLimit(1)
            .truncationMode(.middle)
            .font(font)
            .foregroundColor(textColor)
            .accessibilityIdentifier("EphemeralCountdown")
            .accessibilityElement()
            .layoutPriority(1)
    }
    
    @ViewBuilder
    private func statusImageView(_ image: Image) ->  some View {
        image
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundColor(SemanticColors.Label.textMessageDetails.color)
            .frame(width: 14, height: 14)
            .accessibilityIgnoresInvertColors(true)
    }
    
    @ViewBuilder
    private func statusContainerView(_ state: MessageToolboxState?) -> some View {
        Group {
            if let state = state {
                HStack(spacing: 3) {
                    imageForState(state)
                    if case let .seenByMultiple(count) = state {
                        statusLabel("\(count)")
                    }
                }
            }
        }
    }
    
    private func imageForState(_ state: MessageToolboxState) -> some View {
        statusImageView(Image(uiImage: image(for: state)))
            .accessibilityLabel(accessibilityLabel(for: state))
    }

    private func image(for state: MessageToolboxState) -> UIImage {
        switch state {
        case .sending:
            return UIImage(resource: .sending)
        case .sent:
            return UIImage(resource: .sent)
        case .delivered:
            return UIImage(resource: .delivered)
        case .seen, .seenByMultiple:
            return UIImage(resource: .seen)
        }
    }

    private func accessibilityLabel(for state: MessageToolboxState) -> String {
        switch state {
        case .sending: return "sending"
        case .sent: return "sent"
        case .delivered: return "delivered"
        case .seen: return "seen"
        case .seenByMultiple(let count): return "seen \(count)"
        }
    }

}

#Preview("Sending") {
    MessageToolboxView(
        detailsText: "",
        deliveryStatus: .sending
    )
}

#Preview("Sent") {
    MessageToolboxView(
        detailsText: "18:44",
        deliveryStatus: .sent
    )
}

#Preview("Delivered") {
    MessageToolboxView(
        detailsText: "18:44",
        deliveryStatus: .delivered
    )
}

#Preview("Edited") {
    MessageToolboxView(
        detailsText: "18:44",
        editedString: "Edited: 14:12",
        deliveryStatus: .seenByMultiple(13)
    )
}
