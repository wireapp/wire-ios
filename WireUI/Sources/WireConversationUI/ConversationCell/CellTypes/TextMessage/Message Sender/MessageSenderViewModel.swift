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

import Combine
import SwiftUI
import WireDesign

public protocol SenderObserverProtocol {
    var authorChangedPublisher: AnyPublisher<String, Never> { get }
}

public enum TeamRoleIndicator {
    case guest
    case externalPartner
    case federated
    case service
}

public class MessageSenderViewModelWrapper: ObservableObject {
    
    /// State needed here to be able to update view
    /// because it's not possible to have optional 'MessageSenderViewModel?'
    /// and @Published together
    public enum State {
        case none
        case some(MessageSenderViewModel)
    }
    
    @Published var state: State
    
    public init(state: State) {
        self.state = state
    }
}

public class MessageSenderViewModel: ObservableObject, Identifiable {

    public let id = UUID()

    let avatarViewModel: AvatarViewModel
    private var senderModel: UserModel
    let isDeleted: Bool
    let teamRoleIndicator: TeamRoleIndicator?
    @Published var senderAttributed: AttributedString

    private let authorChanged: any SenderObserverProtocol
    private var cancellables: Set<AnyCancellable> = []

    public init(
        avatarViewModel: AvatarViewModel,
        senderModel: UserModel,
        isDeleted: Bool,
        teamRoleIndicator: TeamRoleIndicator?,
        authorChanged: any SenderObserverProtocol
    ) {
        self.avatarViewModel = avatarViewModel
        self.authorChanged = authorChanged
        self.senderModel = senderModel
        self.isDeleted = isDeleted
        self.teamRoleIndicator = teamRoleIndicator
        self.senderAttributed = Self.makeSenderAttributed(
            senderModel: senderModel,
            isDeleted: isDeleted,
            teamRoleIndicator: teamRoleIndicator
        )

        observeChanges()
    }

    private func observeChanges() {
        authorChanged.authorChangedPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] senderString in
                guard let self else { return }
                print("DS: author ChangedPublisher \(senderString)")
                senderModel.name = senderString
                senderAttributed = Self.makeSenderAttributed(
                    senderModel: senderModel,
                    isDeleted: isDeleted,
                    teamRoleIndicator: teamRoleIndicator
                )
            }.store(in: &cancellables)
    }

    private static func makeSenderAttributed(
        senderModel: UserModel,
        isDeleted: Bool,
        teamRoleIndicator: TeamRoleIndicator?
    ) -> AttributedString {

        let textColor: UIColor = senderModel.isServiceUser ? SemanticColors.Label.textDefault : senderModel.accentColor

        var result = AttributedString(senderModel.name ?? L10n.Name.unavailable)
        result.foregroundColor = Color(textColor)
        result.font = Font(UIFont.mediumSemiboldFont)

        // Paragraph style (max line height) // TODO
//        let lineHeight = UIFont.mediumSemiboldFont.lineHeight
//        let paragraph = NSMutableParagraphStyle()
//        paragraph.maximumLineHeight = lineHeight
//        result.paragraphStyle = paragraph

        // Attachments (convert UIImage to NSTextAttachment and then NSAttributedString, then embed in AttributedString)
        func imageAttachment(_ name: String, size: CGFloat) -> AttributedString? {
            guard let image = UIImage(named: name) else { return nil }
            let attachment = NSTextAttachment()
            attachment.image = image
            attachment.bounds = CGRect(
                x: 0,
                y: (UIFont.mediumSemiboldFont.capHeight - size).rounded() / 2,
                width: size,
                height: size
            )
            return AttributedString(NSAttributedString(attachment: attachment))
        }

        // Indicator icon
        if isDeleted {
            if let imageAttr = imageAttachment("trash", size: 8) { // TODO: addd resources
                result.append(imageAttr)
            }
        }

        // Team role icons
        switch teamRoleIndicator { // TODO: addd resources
        case .guest:
            if let imageAttr = imageAttachment("guest", size: 14) {
                result.append(imageAttr)
            }
        case .externalPartner:
            if let imageAttr = imageAttachment("externalPartner", size: 16) {
                result.append(imageAttr)
            }
        case .federated:
            if let imageAttr = imageAttachment("federated", size: 14) {
                result.append(imageAttr)
            }
        case .service:
            if let imageAttr = imageAttachment("bot", size: 14) {
                result.append(imageAttr)
            }
        default:
            break
        }

        return result

    }

}
