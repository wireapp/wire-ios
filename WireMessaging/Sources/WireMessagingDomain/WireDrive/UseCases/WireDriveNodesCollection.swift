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

@preconcurrency package import Combine

/// A collection of wire drive nodes that can be observed for changes and mutated by various use cases.
@MainActor
package final class WireDriveNodesCollection {

    private let nodesPublisher = PassthroughSubject<[WireDriveNode], Never>()

    private(set) var nodes: [WireDriveNode] = [] {
        didSet {
            nodesPublisher.send(nodes)
        }
    }

    package init() {}

    func setNodes(_ nodes: [WireDriveNode]) {
        self.nodes = nodes
    }

    package func observeNodes() -> AnyPublisher<[WireDriveNode], Never> {
        nodesPublisher.prepend(nodes).eraseToAnyPublisher()
    }

}
