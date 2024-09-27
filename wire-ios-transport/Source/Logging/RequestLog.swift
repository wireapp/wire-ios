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

// MARK: - RequestLog

struct RequestLog: Codable {
    // MARK: Lifecycle

    init?(_ request: NSURLRequest) {
        guard let method = request.httpMethod, let url = request.url else { return nil }
        self.endpoint = url.endpointRemoteLogDescription

        var filteredHeaders = request.allHTTPHeaderFields?.filter {
            Self.authorizedHeaderFields.contains($0.key.lowercased())
        } ?? [:]

        for header in filteredHeaders where Self.notLoggedValues.contains(header.key.lowercased()) {
            filteredHeaders[header.key] = "*******"
        }

        self.headers = filteredHeaders
        self.method = method
    }

    // MARK: Internal

    static let notLoggedValues = Set([
        "Sec-WebSocket-key",
        "Authorization",
        "sec-websocket-accept",
        "Set-cookie",
    ].map { $0.lowercased() })

    static let authorizedHeaderFields = Set([
        "Accept",
        "Accept-Charset",
        "Authorization",
        "Set-cookie",
        "Access-Control-Expose-Headers",
        "Date",
        "Location",
        "Request id",
        "Strict-Transport-Security",
        "Vary",
        "Accept-ranges",
        "Age",
        "Connection",
        "Content-Length",
        "Content-Type",
        "Date",
        "Etag",
        "Last-Modified",
        "Server",
        "Via",
        "X-Amz-Cf-Id",
        "A-Amz-Cf-Pop",
        "X-Amz-Meta-User",
        "X-cache",
        "Sec-WebSocket-key",
        "sec-websocket-accept",
    ].map { $0.lowercased() })

    var method: String
    var endpoint: String
    var headers: [String: String]
}

extension URL {
    var endpointRemoteLogDescription: String {
        let visibleCharactersCount = 3

        var components = URLComponents(string: absoluteString)
        let path = components?.path ?? ""
        let pathComponents = path.components(separatedBy: "/").map { $0.truncated(visibleCharactersCount) }

        var queryComponents = components?.queryItems ?? []
        for item in queryComponents.enumerated() {
            var redactedItem = item.element
            // truncates to 8 digits max for ids
            let value = redactedItem.value?.redactedAndTruncated(
                maxVisibleCharacters: visibleCharactersCount,
                length: 8
            ) ?? ""
            redactedItem.value = value
            queryComponents[item.offset] = redactedItem
        }

        components?.path = pathComponents.joined(separator: "/")
        components?.queryItems = queryComponents

        var endpoint = [components?.host, components?.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: "/")
        endpoint.append(components?.query?.isEmpty == false ? "?\(components!.query!)" : "")
        return endpoint
    }
}

extension String {
    public var redacted: String {
        "*".repeat(count)
    }

    public func `repeat`(_ count: Int) -> String {
        String(repeating: self, count: count)
    }

    public func redactedAndTruncated(maxVisibleCharacters: Int = 7, length: Int = 10) -> String {
        if count <= maxVisibleCharacters {
            return redacted
        }
        let newString = truncated(maxVisibleCharacters)
        return String(newString.prefix(length))
    }

    public func truncated(_ maxCharacters: Int) -> String {
        let result = String(prefix(maxCharacters))
        let fillCount = count - result.count
        return result + "*".repeat(fillCount)
    }
}

extension WireLogger {
    func log(request: NSURLRequest) {
        let info = RequestLog(request)

        do {
            let data = try JSONEncoder().encode(info)
            let jsonString = String(decoding: data, as: UTF8.self)
            let message = "REQUEST: \(jsonString)"
            self.info(message, attributes: .safePublic)
        } catch {
            let message = "REQUEST: \(request.description)"
            self.error(message, attributes: .safePublic)
        }
    }

    func log(response: HTTPURLResponse) {
        guard let info = ResponseLog(response) else { return }

        do {
            let data = try JSONEncoder().encode(info)
            let jsonString = String(decoding: data, as: UTF8.self)
            let message = "RESPONSE: \(jsonString)"
            self.info(message, attributes: .safePublic)
        } catch {
            let message = "RESPONSE: \(response.description)"
            self.error(message, attributes: .safePublic)
        }
    }
}

extension WireLoggerObjc {
    static func logRequest(_ request: NSURLRequest) {
        WireLogger.network.log(request: request)
    }

    static func logHTTPResponse(_ response: HTTPURLResponse) {
        WireLogger.network.log(response: response)
    }

    @objc(logRequestLoopAtPath:)
    static func logRequestLoop(at path: String) {
        WireLogger.network.warn("Request loop detected for \(path)", attributes: .safePublic)
    }
}
