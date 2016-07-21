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

extension AVSMediaManager {
    private func settingsPropertyFactory() -> SettingsPropertyFactory {
        let settingsPropertyFactory = SettingsPropertyFactory(userDefaults: NSUserDefaults.standardUserDefaults(),
                                                              analytics: Analytics.shared(),
                                                              mediaManager: AVSProvider.shared.mediaManager,
                                                              userSession: ZMUserSession.sharedSession(),
                                                              selfUser: ZMUser.selfUser())
        return settingsPropertyFactory
    }
    
    func observeSoundConfigurationChanges() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AVSMediaManager.didUpdateSound(_:)), name: SettingsPropertyName.MessageSoundName.changeNotificationName, object: .None)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AVSMediaManager.didUpdateSound(_:)), name: SettingsPropertyName.CallSoundName.changeNotificationName, object: .None)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AVSMediaManager.didUpdateSound(_:)), name: SettingsPropertyName.PingSoundName.changeNotificationName, object: .None)
    }
    
    func configureCustomSounds() {
        let settingsPropertyFactory = self.settingsPropertyFactory()
        
        let messageSoundProperty = settingsPropertyFactory.property(.MessageSoundName)
        self.updateCustomSoundForProperty(messageSoundProperty)
        
        let callSoundProperty = settingsPropertyFactory.property(.CallSoundName)
        self.updateCustomSoundForProperty(callSoundProperty)
        
        let pingSoundProperty = settingsPropertyFactory.property(.PingSoundName)
        self.updateCustomSoundForProperty(pingSoundProperty)
    }
    
    func updateCustomSoundForProperty(property: SettingsProperty) {
        let name = property.propertyName.rawValue
        let value = property.propertyValue.value()
        if let stringValue = value as? String {
            self.updateCustomSoundForName(name, propertyValue: stringValue)
        }
    }
    
    @objc func updateCustomSoundForName(propertyName: String, propertyValue: String?) {
        let value = propertyValue
        
        let soundValue = value == .None ? .None : ZMSound(rawValue: value!)
        
        switch propertyName {
        case SettingsPropertyName.MessageSoundName.rawValue:
            self.registerUrl(soundValue?.fileURL(), forMedia: MediaManagerSoundFirstMessageReceivedSound)
            self.registerUrl(soundValue?.fileURL(), forMedia: MediaManagerSoundMessageReceivedSound)
            
        case SettingsPropertyName.CallSoundName.rawValue:
            self.registerUrl(soundValue?.fileURL(), forMedia: MediaManagerSoundRingingFromThemInCallSound)
            self.registerUrl(soundValue?.fileURL(), forMedia: MediaManagerSoundRingingFromThemSound)
            
        case SettingsPropertyName.PingSoundName.rawValue:
            self.registerUrl(soundValue?.fileURL(), forMedia: MediaManagerSoundOutgoingKnockSound)
            self.registerUrl(soundValue?.fileURL(), forMedia: MediaManagerSoundIncomingKnockSound)
            
        default:
            fatalError("\(propertyName) is not a sound property")
        }
    }
    
    // MARK: - Notifications
    func didUpdateSound(notification: NSNotification?) {
        self.configureSounds()
    }
}
