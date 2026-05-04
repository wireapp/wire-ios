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

import Foundation

extension Error {

    /// Returns `true` if self is a URLError(.cancelled) otherwise `false`.
    var isURLErrorCancelled: Bool {
        isURLError(.cancelled)
    }

    /// Returns `true` if self is a URLError(.notConnectedToInternet) or URLError(.networkConnectionLost) otherwise
    /// `false`.
    var isNoInternetError: Bool {
        isURLError(.notConnectedToInternet, .networkConnectionLost)
    }

    /// Returns `true` if self is a URLError with one of the given codes, otherwise `false`.
    func isURLError(_ code: URLError.Code...) -> Bool {
        guard let urlError = self as? URLError else { return false }
        return code.contains(urlError.code)
    }

}
