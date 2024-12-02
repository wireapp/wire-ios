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

extension WireLogger {

    nonisolated(unsafe) private static var loggingSystem: (any WireLoggingSystem)!

    /// This method is supposed to be called very early on app start, before any other interaction with ``WireLogger``.
    @MainActor
    public static func setup(_ loggingSystem: any WireLoggingSystem) {
        guard self.loggingSystem == nil else {
            fatalError("WireLogger is already set up")
        }

        self.loggingSystem = loggingSystem
    }

    nonisolated(unsafe) static var network = WireLogger("network") { loggingSystem }
}
