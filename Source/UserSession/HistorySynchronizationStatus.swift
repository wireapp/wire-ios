// 
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
// 


import Foundation

@objc public protocol HistorySynchronizationStatus : NSObjectProtocol
{
    /// Should be called when the sync is completed
    func didCompleteSync()
    
    /// Should be called when the sync is started
    func didStartSync()
    
    /// Whether the history can now be downloaded
    var shouldDownloadFullHistory : Bool { get }
}

@objc public class ForegroundOnlyHistorySynchronizationStatus : NSObject, HistorySynchronizationStatus
{
    private var isSyncing = false
    private var isInBackground = false
    
    /// Managed object context used to execute on the right thread
    private var moc : NSManagedObjectContext
    
    public init(managedObjectContext: NSManagedObjectContext) {
        moc = managedObjectContext
        isSyncing = true
        isInBackground = false
        super.init()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(UIApplicationDelegate.applicationDidBecomeActive(_:)), name: UIApplicationDidBecomeActiveNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(UIApplicationDelegate.applicationWillResignActive(_:)), name: UIApplicationWillResignActiveNotification, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    public func applicationDidBecomeActive(note: NSNotification) {
        self.moc.performGroupedBlock { () -> Void in
            self.isInBackground = false
        }
    }

    public func applicationWillResignActive(note: NSNotification) {
        self.moc.performGroupedBlock { () -> Void in
            self.isInBackground = true
        }
    }

    
    /// Should be called when the initial synchronization is done
    public func didCompleteSync() {
        self.isSyncing = false
    }
    
    /// Should be called when some synchronization (slow or quick) is started
    public func didStartSync() {
        self.isSyncing = true
    }
    
    /// Returns whether history should be downloaded now
    public var shouldDownloadFullHistory : Bool {
        return !self.isSyncing && !self.isInBackground;
    }
}

