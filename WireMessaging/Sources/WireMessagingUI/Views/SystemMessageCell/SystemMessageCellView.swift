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

struct SystemMessageCellView: View {
    
    @StateObject var viewModel: SystemMessageCellViewModel
    var body: some View {
        
        VStack(alignment: .leading, spacing: PaddingConstants.medium) {
            HStack(alignment: .top , spacing: UIConstants.imageTextSpacing) {
                if let imageResource = viewModel.systemMessageModal.icon {
                    Image(imageResource)
                        .resizable()
                        .frame(width: UIConstants.iconWidthAndHeight, height: UIConstants.iconWidthAndHeight)
                        .padding(.leading, PaddingConstants.large)
                    
                }
                
                Text(viewModel.systemMessageModal.titleLabel ?? "")
                    .padding(.trailing, PaddingConstants.defaultPadding)
                    .multilineTextAlignment(.leading)
                    .environment(\.openURL, OpenURLAction { url in
                        // This closure is called when a link is tapped.
                        print("Link tapped with URL: \(url)")
                        
                        // You can add any custom logic here, like navigating
                        // to a different screen or showing a sheet.
                        
                        // Return .handled to signify that you've dealt with the
                        // tap and don't want SwiftUI to perform its default
                        // action (like opening the browser).
                        // This can be removed if we want the link to be opened in default browser
                        return .handled
                    })
            }
            
            if let buttonTitle = viewModel.systemMessageModal.buttonActionItem?.title {
                Button(buttonTitle) {
                    viewModel.systemMessageModal.buttonActionItem?.action()
                }
                .padding(.leading, UIConstants.buttonLeadingPadding)
                .wireButtonStyle(.tertiary)
            }
        }
                
        .padding(.horizontal, PaddingConstants.defaultPadding)
    }
}


// MARK: - Preview
struct SystemMessageCellView_Previews: PreviewProvider {
    static var previews: some View {
        let buttonItem = SystemMessageCellModel.ButtonActionItem(title: "Show Details", action: { print("Button tapped!") })
        let systemMessageModal: SystemMessageCellModel = SystemMessageCellModel(icon: .certificateValid,
                                   titleLabel: buildComplexMessage(),
                                   buttonActionItem: buttonItem)
        
        ScrollView {
            VStack(spacing: 20) {
                SystemMessageCellView(viewModel: SystemMessageCellViewModel(systemMessageModal: systemMessageModal))
                
            }
        }
    }
        
        // Helper function to create a link for the preview
        static func link(text: String) -> AttributedString {
            var attributed = AttributedString(text) // Correctly use the 'text' parameter
            attributed.underlineStyle = .single
            attributed.link = URL(string: "https://wire.com")
            return attributed
        }
    
    // Helper function to demonstrate building the complex string
       static func buildComplexMessage() -> AttributedString {
           // 1. Create the main text part
           var fullString = AttributedString("Communication in Wire is always end-to-end encrypted. Everything you send and receive in this channel is only accessible to you and other group participants. Please still be careful with who you share sensitive information. ")
           
           // 2. Create the link part using the helper function
           let learnMoreLink = link(text: "Learn more")
           
           // 3. Append the link to the main text. This modifies fullString in place.
           fullString.append(learnMoreLink)
           
           // 4. Return the final, combined string
           return fullString
       }
}

// MARK: Constants
private extension SystemMessageCellView {
    enum UIConstants {
        static let iconWidthAndHeight: CGFloat = 14.0
        static let imageTextSpacing: CGFloat = 12.0
        static let buttonLeadingPadding: CGFloat = 52.0
    }
}
