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

public import Foundation

// NOTE: This protocol is intentionally NOT annotated `// sourcery: AutoMockable`. Its mock is
// hand-written in `WireMessagingDomainSupport/MockWireDriveFetchNodeUseCaseProtocol.swift` because
// `invoke(nodeID:)` is called concurrently (one TaskGroup child per attachment in
// `MessageReplyAttachmentsViewModel.latestVisibleAttachments`). The AutoMockable-generated mock is
// `@unchecked Sendable` but records invocations by appending to an array without synchronisation,
// which is a data race that crashes under concurrent calls. The manual mock locks that recording.
public protocol WireDriveFetchNodeUseCaseProtocol: Sendable {
    func invoke(nodeID: UUID) async throws -> WireDriveNode?
}
