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

public enum DeveloperOverrides {

    public nonisolated(unsafe) static var storage: UserDefaults?

    private static let buildNumberKey = "buildNumberOverride"
    public static var buildNumber: String? {
        get {
            storage?.string(forKey: buildNumberKey)
        } set {
            storage?.setValue(newValue, forKey: buildNumberKey)
        }
    }

    private static let obsoleteBackendEnvKey = "obsoleteBackendEnvOverride"
    public static var obsoleteBackendEnv: String? {
        get {
            storage?.string(forKey: obsoleteBackendEnvKey)
        } set {
            storage?.setValue(newValue, forKey: obsoleteBackendEnvKey)
        }
    }

    private static let obsoleteClientEnvKey = "obsoleteClientEnvOverride"
    public static var obsoleteClientEnv: String? {
        get {
            storage?.string(forKey: obsoleteClientEnvKey)
        } set {
            storage?.setValue(newValue, forKey: obsoleteClientEnvKey)
        }
    }

}
