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
    let emoji: String
    let senderName: String
    var yOffset: CGFloat
    var opacity: Double
}

@MainActor
@Observable
final class CallReactionWallViewModel {

    private(set) var items: [ReactionItem] = []

    private var cancellable: AnyCancellable?

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
        items.append(ReactionItem(id: id, emoji: event.emoji, senderName: event.senderName, yOffset: 0, opacity: 1))

        withAnimation(.easeOut(duration: 3)) {
            guard let index = items.firstIndex(where: { $0.id == id }) else { return }
            items[index].yOffset = -220
            items[index].opacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.1) { [weak self] in
            self?.items.removeAll { $0.id == id }
        }
    }
}
