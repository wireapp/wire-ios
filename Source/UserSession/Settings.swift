// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
// along with this program. If not, see <http://www.gnu.org/licenses/>.


enum SettingsKeys {
    case ShouldSendOnlyEncrypted
}

@objc
public class ZMSettings: NSObject {
    
    /// Shared settings
    public static let sharedSettings : ZMSettings = ZMSettings()
    
    /// Isolation queue to change settings
    private let isolationQueue : dispatch_queue_t
    
    /// Internal settings storage
    private var settingsStorage : [SettingsKeys:Bool]
    
    override init() {
        isolationQueue = dispatch_queue_create("ZMSettings", DISPATCH_QUEUE_CONCURRENT)
        settingsStorage = [:]
        super.init()
    }
    
    /// Gets the boolean value of a key with a sync barrier
    private func getBoolValue(key: SettingsKeys) -> Bool {
        var value : Bool?
        dispatch_sync(isolationQueue) {
            value = self.settingsStorage[key]
        }
        if let value = value {
            return value
        }
        return false;
    }
    
    /// Sets the boolean value of a key with an async barrier
    private func setBoolValue(key: SettingsKeys, value: Bool) {
        dispatch_barrier_async(isolationQueue) {
            self.settingsStorage[key] = value
        }
    }
}
