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
import WireCoreCrypto
import WireLogging

final class CoreCryptoLoggerProxy: CoreCryptoLogger {

    func log(
        level: CoreCryptoLogLevel,
        message: String,
        context: String?
    ) {
        var attributes: LogAttributes = [:]

        if let context {
            attributes[.coreCryptoContext] = context
        }

        switch level {
        case .off:
            return
        case .trace, .debug:
            WireLogger.coreCrypto.debug(
                message,
                attributes: attributes
            )
        case .info:
            WireLogger.coreCrypto.info(
                message,
                attributes: attributes
            )
        case .warn:
            WireLogger.coreCrypto.warn(
                message,
                attributes: attributes
            )
        case .error:
            WireLogger.coreCrypto.error(
                message,
                attributes: attributes
            )
        @unknown default:
            WireLogger.coreCrypto.debug(
                message,
                attributes: attributes
            )
        }
    }

}
