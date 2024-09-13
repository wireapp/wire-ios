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

@objc
extension ZMTransportRequest {
    public var URL: URL {
        Foundation.URL(string: path)!
    }

    // It would be better to use `queryItems: [URLQueryItem]`,
    // because an array is sorted (compared to dictionary here).
    // It can make a difference in the final call,
    // e.g. for caching requests and have them equal with other platforms.
    public var queryParameters: [String: Any] {
        queryItems.reduce(into: [:]) { partialResult, queryItem in
            partialResult[queryItem.name] = queryItem.value
        }
    }

    public var queryItems: [URLQueryItem] {
        let urlComponents = URLComponents(string: path)
        return urlComponents?.queryItems ?? []
    }

    public var multipartBodyItemsFromRequestOrFile: [ZMMultipartBodyItem] {
        if let items = multipartBodyItems() as? [ZMMultipartBodyItem] {
            return items
        }

        guard let fileURL = fileUploadURL,
              let multipartData = try? Data(contentsOf: fileURL)
        else {
            return []
        }

        return (
            (multipartData as NSData)
                .multipartDataItemsSeparated(withBoundary: "frontier") as? [ZMMultipartBodyItem]
        ) ?? []
    }

    @objc(RESTComponentAtIndex:)
    public func RESTComponents(index: Int) -> String? {
        guard pathComponents.count > index, index > 0 else {
            return nil
        }
        return pathComponents[index]
    }

    private var pathComponents: [String] {
        var components = URL.path.components(separatedBy: "/").filter { !$0.isEmpty }

        // remove api version from path components
        let versions = APIVersion.allCases.map { "v\($0.rawValue)" }
        if let version = components.first, versions.contains(version) {
            components.removeFirst()
        }

        return components
    }
}

@objc
extension ZMTransportRequest {
    /// Returns whether the path of the request matches the given string.
    /// Wildcards are allowed using the special symbol "*"
    /// E.g. `/users/ * /clients` will match `/users/ab12da/clients`
    public func matches(path: String, method: ZMTransportRequestMethod) -> Bool {
        self.method == method && matches(path: path)
    }
}

extension ZMTransportRequest {
    /// Returns whether the path of the request matches the given string.
    /// Wildcards are allowed using the special symbol "*"
    /// E.g. `/users/ * /clients` will match `/users/ab12da/clients`
    public func matches(path: String) -> Bool {
        let pathComponents = pathComponents
        let expectedComponents = path.components(separatedBy: "/").filter { !$0.isEmpty }

        guard pathComponents.count == expectedComponents.count else {
            return false
        }

        return zip(expectedComponents, pathComponents).first(where: { expected, actual -> Bool in
            expected != "*" && expected != actual
        }) == nil
    }

    public static func ~= (path: String, request: ZMTransportRequest) -> Bool {
        request.matches(path: path)
    }
}
