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

import Combine
import SwiftUI
import WireDomain

struct ReactionItem: Identifiable {
    let id: UUID
    let senderID: UUID
    let emoji: String
    let senderName: String
    let xOffset: CGFloat
    var yOffset: CGFloat
    var opacity: Double
}

@MainActor
@Observable
final class CallReactionWallViewModel {

    private(set) var items: [ReactionItem] = []
    var containerHeight: CGFloat = 800

    /// Last emoji received per sender, held for 1 second after the floating animation ends.
    /// Keyed by sender user ID so video tiles can badge the sender.
    private(set) var lastReactions: [UUID: String] = [:]

    private var cancellable: AnyCancellable?
    private var expiryWorkItems: [UUID: DispatchWorkItem] = [:]
    private let reactionsSubject = PassthroughSubject<[UUID: String], Never>()

    var reactionsPublisher: AnyPublisher<[UUID: String], Never> {
        reactionsSubject.eraseToAnyPublisher()
    }

    init(publisher: AnyPublisher<CallReactionEvent, Never>, conversationID: UUID) {
        cancellable = publisher
            .filter { $0.conversationID == conversationID }
            .receive(on: RunLoop.main)
            .sink { [weak self] event in
                self?.add(event)
            }
    }

    private func add(_ event: CallReactionEvent) {
        let id = UUID()
        items.append(ReactionItem(
            id: id,
            senderID: event.senderID,
            emoji: event.emoji,
            senderName: event.senderName,
            xOffset: CGFloat.random(in: 16...260),
            yOffset: 0,
            opacity: 1
        ))

        withAnimation(.easeOut(duration: 2.5)) {
            guard let index = items.firstIndex(where: { $0.id == id }) else { return }
            items[index].yOffset = -containerHeight
        }

        withAnimation(.easeOut(duration: 1.0).delay(1.5)) {
            guard let index = items.firstIndex(where: { $0.id == id }) else { return }
            items[index].opacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) { [weak self] in
            guard let self else { return }
            guard let item = items.first(where: { $0.id == id }) else { return }
            items.removeAll { $0.id == id }
            recordLastReaction(emoji: item.emoji, senderID: item.senderID)
        }
    }

    private func recordLastReaction(emoji: String, senderID: UUID) {
        lastReactions[senderID] = emoji
        reactionsSubject.send(lastReactions)

        expiryWorkItems[senderID]?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.lastReactions.removeValue(forKey: senderID)
            self?.expiryWorkItems.removeValue(forKey: senderID)
            self.map { $0.reactionsSubject.send($0.lastReactions) }
        }
        expiryWorkItems[senderID] = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: workItem)
    }
}
