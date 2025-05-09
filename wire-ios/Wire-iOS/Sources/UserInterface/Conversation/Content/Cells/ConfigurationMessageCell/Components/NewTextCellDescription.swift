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

import Foundation
import Combine
import UIKit
import WireConversationUI
import WireFoundation
import WireSystem
import WireDataModel
import WireSyncEngine
import WireDesign

protocol NewCellDescription { }
extension NewTextCellDescription: NewCellDescription { }
extension BurstTimestampSenderMessageCellDescription: NewCellDescription { }

final class SenderObserver: NSObject, ZMMessageObserver, SenderObserverProtocol {
    
    var observation: Any?
    
    var author: String?
    private let authorChangedSubject = PassthroughSubject<String, Never>()
    var authorChangedPublisher: AnyPublisher<String, Never> {
        authorChangedSubject
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    
    init(
        messageID: NSManagedObjectID,
        viewContext: NSManagedObjectContext
    ) {
        super.init()
        viewContext.perform {
            let message = try! viewContext.existingObject(with: messageID) as! ZMMessage
            self.author = message.senderName
            self.observation = MessageChangeInfo
                .add(
                    observer: self,
                    for: message,
                    context: viewContext)
        }
    }
    
    func messageDidChange(_ changeInfo: WireDataModel.MessageChangeInfo) {
        authorChangedSubject.send(changeInfo.message.senderName)
    }
}

final class NewTextCellDescription: ConversationMessageCellDescription {
    
    typealias View = NewTextCell

    @MainActor var conversationCellModel: ConversationCellModel?
    
    var supportsActions: Bool = true
    
    private var cancellables: Set<AnyCancellable> = []

//    func makeConversationCellModel(message: ZMMessage) -> ConversationCellModel {
//        
//        model.significantChangeSubject.sink { [weak self] _ in
//            guard let self else { return }
//            delegate?.conversationMessageDidRequestToUpdate(nonce: self.nonce)
//        }.store(in: &cancellables)
//        return ConversationCellModel.text(model)
//    }

    var configuration: View.Configuration {
        .init(text: "", author: "", accentColor: .red)
    }

    weak var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    var topMargin = CGFloat()
    var bottomMargin = CGFloat()

    let containsHighlightableContent = false

    let accessibilityIdentifier: String? = nil
    let accessibilityLabel: String? = nil
    
    init(
        conversationCellModel: ConversationCellModel
    ) {
        self.conversationCellModel = conversationCellModel
    }

//    convenience init(
//        message: ZMConversationMessage,
//        context: ConversationMessageContext,
//        accentColor: UIColor
//    ) {
//        let configuration = View.Configuration(
//            text: message.textMessageData?.messageText ?? "",
//            author: message.senderName,
//            accentColor: accentColor
//        )
//        self.init(configuration: configuration, message: message as! ZMMessage)
//    }

}

final class NewTextCell: UIView, ConversationMessageCell {

    struct Configuration: Equatable {
        let text: String
        let author: String
        let accentColor: UIColor
    }

    weak var delegate: ConversationMessageCellDelegate?
    weak var message: ZMConversationMessage?
    weak var actionController: ConversationMessageActionController?

    var isSelected: Bool = false

    func configure(with object: Configuration, animated: Bool) {}

}

extension ZMDeliveryState {
    func toUIModel() -> DeliveryState {
        switch self {
        case .invalid:
                .invalid
        case .pending:
                .pending
        case .sent:
                .sent
        case .delivered:
                .delivered
        case .read:
                .read
        case .failedToSend:
                .failedToSend
        }
    }
}
