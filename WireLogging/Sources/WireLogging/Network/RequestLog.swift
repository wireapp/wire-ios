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

struct RequestLog: Codable {
    var method: String
    var endpoint: String
    var headers: [String: String]

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

    static let notLoggedValues = Set([
        "Sec-WebSocket-key",
        "Authorization",
        "sec-websocket-accept",
        "Set-cookie"
    ].map { $0.lowercased() })

    static let authorizedHeaderFields = Set(
        [
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
            "sec-websocket-accept"
        ].map { $0.lowercased() }
    )
}

public extension URL {
    var endpointRemoteLogDescription: String {
        absoluteString
    }
}

public extension String {
    var redacted: String {
        "*".repeat(count)
    }

    func `repeat`(_ count: Int) -> String {
        String(repeating: self, count: count)
    }

    func redactedAndTruncated(maxVisibleCharacters: Int = 7, length: Int = 10) -> String {
        if count <= maxVisibleCharacters {
            return redacted
        }
        let newString = truncated(maxVisibleCharacters)
        return String(newString.prefix(length))
    }

    func truncated(_ maxCharacters: Int) -> String {
        let result = String(prefix(maxCharacters))
        let fillCount = count - result.count
        return result + "*".repeat(fillCount)
    }
}

public extension WireLogger {

    static var defaultEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        return encoder
    }

    func log(_ request: URLRequest) {
        log(request: request as NSURLRequest)
    }

    func log(request: NSURLRequest) {
        let info = RequestLog(request)

        do {
            let data = try Self.defaultEncoder.encode(info)
            let jsonString = String(decoding: data, as: UTF8.self)
            let message = "REQUEST: \(jsonString)"
            self.info(message, attributes: .safePublic)
        } catch {
            let message = "REQUEST: \(request.description)"
            self.error(message, attributes: .safePublic)
        }
    }

    func log(response: HTTPURLResponse, body: Data? = nil) {
        guard let info = ResponseLog(response, body: body) else { return }

        do {
            let data = try Self.defaultEncoder.encode(info)
            let jsonString = String(decoding: data, as: UTF8.self)
            let message = "RESPONSE: \(jsonString)"
            self.info(message, attributes: .safePublic)
        } catch {
            let message = "RESPONSE: \(response.description)"
            self.error(message, attributes: .safePublic)
        }
    }
}
