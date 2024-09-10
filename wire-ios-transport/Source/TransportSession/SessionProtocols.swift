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

/// The following protocols are used in `UnauthenticatedTransportSession`
/// to enable easy injection of mocks in tests.

public protocol SessionProtocol {
    func task(
        with request: URLRequest,
        completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void
    ) -> DataTaskProtocol
}

public protocol DataTaskProtocol {
    func resume()
}

// MARK: - Conformances

extension URLSessionDataTask: DataTaskProtocol {}

extension URLSession: SessionProtocol {
    public func task(
        with request: URLRequest,
        completionHandler: @escaping (Data?, URLResponse?, Error?
        ) -> Void) -> DataTaskProtocol {
        dataTask(with: request, completionHandler: completionHandler) as DataTaskProtocol
    }
}
