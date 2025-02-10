//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
import WireLogging

struct PreviewLogger: LoggerProtocol {

    let logFiles = [URL]()

    func addTag(_ key: LogAttributesKey, value: String?) {}

    func debug(_ message: any LogConvertible, attributes: LogAttributes...) {
        print("[debug] \(message)")
    }

    func info(_ message: any LogConvertible, attributes: LogAttributes...) {
        print("[info] \(message)")
    }

    func notice(_ message: any LogConvertible, attributes: LogAttributes...) {
        print("[notice] \(message)")
    }

    func warn(_ message: any LogConvertible, attributes: LogAttributes...) {
        print("[warn] \(message)")
    }

    func error(_ message: any LogConvertible, attributes: LogAttributes...) {
        print("[error] \(message)")
    }

    func critical(_ message: any LogConvertible, attributes: LogAttributes...) {
        print("[critical] \(message)")
    }

}
