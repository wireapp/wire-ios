//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

// MARK: - Set message flags

extension GenericMessage {
    var legalHoldStatus: LegalHoldStatus {
        guard let content else { return .unknown }
        switch content {
        case .ephemeral:
            return ephemeral.legalHoldStatus
        case .reaction:
            return reaction.legalHoldStatus
        case .knock:
            return knock.legalHoldStatus
        case .text:
            return text.legalHoldStatus
        case .location:
            return location.legalHoldStatus
        case .asset:
            return asset.legalHoldStatus
        default:
            return .unknown
        }
    }

    public mutating func setLegalHoldStatus(_ status: LegalHoldStatus) {
        guard let content else { return }
        switch content {
        case .ephemeral:
            ephemeral.updateLegalHoldStatus(status)
        case .reaction:
            reaction.legalHoldStatus = status
        case .knock:
            knock.legalHoldStatus = status
        case .text:
            text.legalHoldStatus = status
        case .location:
            location.legalHoldStatus = status
        case .asset:
            asset.legalHoldStatus = status
        default:
            return
        }
    }

    public mutating func setExpectsReadConfirmation(_ value: Bool) {
        guard let content else { return }
        switch content {
        case .ephemeral:
            ephemeral.updateExpectsReadConfirmation(value)
        case .knock:
            knock.expectsReadConfirmation = value
        case .text:
            text.expectsReadConfirmation = value
        case .location:
            location.expectsReadConfirmation = value
        case .asset:
            asset.expectsReadConfirmation = value
        default:
            return
        }
    }
}

extension Ephemeral {
    public var legalHoldStatus: LegalHoldStatus {
        guard let content else { return .unknown }
        switch content {
        case let .text(value):
            return value.legalHoldStatus
        case .image:
            return .unknown
        case let .knock(value):
            return value.legalHoldStatus
        case let .asset(value):
            return value.legalHoldStatus
        case let .location(value):
            return value.legalHoldStatus
        }
    }

    public mutating func updateLegalHoldStatus(_ status: LegalHoldStatus) {
        guard let content else { return }
        switch content {
        case .text:
            text.legalHoldStatus = status
        case .image:
            break
        case .knock:
            knock.legalHoldStatus = status
        case .asset:
            asset.legalHoldStatus = status
        case .location:
            location.legalHoldStatus = status
        }
    }

    public mutating func updateExpectsReadConfirmation(_ value: Bool) {
        guard let content else { return }
        switch content {
        case .text:
            text.expectsReadConfirmation = value
        case .image:
            break
        case .knock:
            knock.expectsReadConfirmation = value
        case .asset:
            asset.expectsReadConfirmation = value
        case .location:
            location.expectsReadConfirmation = value
        }
    }
}
