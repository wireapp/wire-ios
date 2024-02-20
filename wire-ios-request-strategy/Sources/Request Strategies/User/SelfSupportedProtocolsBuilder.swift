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
import WireTransport

struct SelfSupportedProtocolsBuilder {
    private enum Constant {
        static let path = "/self/supported-protocols"
    }

    var apiVersion: APIVersion
    var supportedProtocols: Set<MessageProtocol>

    private var supportedAPIVersion: Bool {
        apiVersion >= .v4
    }

    // MARK: Funcs

    func buildTransportRequest() -> ZMTransportRequest? {
        guard supportedAPIVersion else {
            return nil
        }

        let payload = ["supported_protocols": supportedProtocols.map(\.rawValue)]

        return ZMTransportRequest(
            path: Constant.path,
            method: .put,
            payload: payload as ZMTransportData,
            apiVersion: apiVersion.rawValue
        )
    }

    func buildUpstreamRequest(keys: Set<String>) -> ZMUpstreamRequest? {
        guard let transportRequest = buildTransportRequest() else {
            return nil
        }
        return ZMUpstreamRequest(
            keys: keys,
            transportRequest: transportRequest
        )
    }
}
