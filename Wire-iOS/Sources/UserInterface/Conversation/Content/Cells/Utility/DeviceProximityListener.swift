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
// along with this program. If not, see http://www.gnu.org/licenses/.
// 


import Foundation
import CoreMotion

class DeviceProximityListener: NSObject {
    private var heldVertically: Bool = false
    
    private(set) var raisedToEar: Bool = false {
        didSet {
            if oldValue != self.raisedToEar {
                self.stateChanged?(raisedToEar: self.raisedToEar)
            }
        }
    }
    
    var stateChanged:((raisedToEar: Bool)->())? = nil
    
    var listening: Bool = false
    
    override init() {
        super.init()
        let motionManager = CMMotionManager()
        motionManager.deviceMotionUpdateInterval = 10.0 / 60.0
        
        // Only listen for UIDevice proximity if the device is held vertically
        let handler: CMDeviceMotionHandler = { [weak self] weakMotion, error in
            guard let `self` = self, motion = weakMotion else {
                return
            }
            
            self.heldVertically = (motion.gravity.z > -0.4 &&
                                   motion.gravity.z < 0.4 &&
                                   motion.gravity.y < -0.7)
        }
        motionManager.startDeviceMotionUpdatesUsingReferenceFrame(.XArbitraryZVertical,
                                                          toQueue: NSOperationQueue(),
                                                      withHandler: handler)
    }
    
    static var totalListeners: UInt = 0 {
        didSet {
            if self.totalListeners > 0 {
                UIDevice.currentDevice().proximityMonitoringEnabled = true
            }
            else {
                UIDevice.currentDevice().proximityMonitoringEnabled = false
            }
        }
    }
    
    func startListening() {
        guard !self.listening else {
            return
        }
        self.listening = true
        self.dynamicType.totalListeners = self.dynamicType.totalListeners + 1
        NSNotificationCenter.defaultCenter().addObserver(self,
                                               selector: #selector(DeviceProximityListener.handleProximityChange(_:)),
                                                   name: UIDeviceProximityStateDidChangeNotification, object: nil)
    }
    
    func stopListening() {
        guard self.listening else {
            return
        }
        self.listening = false
        self.dynamicType.totalListeners = self.dynamicType.totalListeners - 1
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func handleProximityChange(notification: NSNotification) {
        self.raisedToEar = UIDevice.currentDevice().proximityState &&
                           self.heldVertically
    }
    
    deinit {
        self.stopListening()
    }
}
