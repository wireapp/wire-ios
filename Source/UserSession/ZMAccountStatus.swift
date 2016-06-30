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


import ZMTransport
import ZMCDataModel

@objc public enum AccountState : UInt {
    case NewDeviceNewAccount // we don't want to show any system message
    case NewDeviceExistingAccount // we want to show "you are using a new device"
    case OldDeviceDeactivatedAccount // we want to show "you are using this device again"
    case OldDeviceActiveAccount // we don't want to show any system message
}


@objc public protocol ZMCookieProvider : NSObjectProtocol {
    var authenticationCookieData : NSData! { get }
}

extension ZMPersistentCookieStorage : ZMCookieProvider {
}

public class ZMAccountStatus : NSObject, ZMInitialSyncCompletionObserver, ZMAuthenticationObserver, ZMRegistrationObserver {

    let managedObjectContext: NSManagedObjectContext
    let cookieStorage : ZMCookieProvider
    var authenticationToken : ZMAuthenticationObserverToken!
    var registrationToken : ZMRegistrationObserverToken!
    
    var didRegister: Bool = false
    public private (set) var currentAccountState : AccountState = .NewDeviceNewAccount
    
    public lazy var hadHistoryBeforeLogin : Bool = {
        let convRequest = NSFetchRequest.init(entityName:ZMConversation.entityName())
        let convCount = self.managedObjectContext.countForFetchRequest(convRequest, error: nil)
        let hasHistory = convCount > 1
        return hasHistory
    }()
    
    var hasCookie : Bool {
        return cookieStorage.authenticationCookieData != nil
    }
    
    @objc public func initialSyncCompleted(note: NSNotification){
        self.managedObjectContext.performGroupedBlock { 
            if self.currentAccountState == .OldDeviceDeactivatedAccount || self.currentAccountState == .NewDeviceExistingAccount {
                self.appendMessage(self.currentAccountState)
                self.managedObjectContext.saveOrRollback()
            }
            self.currentAccountState = .OldDeviceActiveAccount
        }
    }
    
    func didAuthenticate() {
        self.managedObjectContext.performGroupedBlock {
            if self.currentAccountState == .NewDeviceNewAccount && !self.didRegister {
                self.currentAccountState = .NewDeviceExistingAccount
            }
        }
    }
    
    func failedToAuthenticate() {
        self.managedObjectContext.performGroupedBlock {
            if self.currentAccountState == .OldDeviceActiveAccount && !self.hasCookie {
                self.currentAccountState = .OldDeviceDeactivatedAccount
            }
        }
    }
    
    func appendMessage(state: AccountState){
        let convRequest = NSFetchRequest.init(entityName:ZMConversation.entityName())
        guard let conversations = managedObjectContext.executeFetchRequestOrAssert(convRequest) as? [ZMConversation]
            else { return }
        
        conversations.forEach{
            guard $0.conversationType == .OneOnOne || $0.conversationType == .Group else { return }
            switch state {
            case .OldDeviceDeactivatedAccount:
                $0.appendContinuedUsingThisDeviceMessage()
            case .NewDeviceExistingAccount:
                $0.appendStartedUsingThisDeviceMessage()
            default:
                return
            }
        }
    }
    
    @objc public init(managedObjectContext: NSManagedObjectContext, cookieStorage: ZMCookieProvider) {
        self.managedObjectContext = managedObjectContext
        self.cookieStorage = cookieStorage
        
        super.init()
        
        switch (hasCookie, hadHistoryBeforeLogin) {
        case (true, true):
            currentAccountState = .OldDeviceActiveAccount
        case (false, true):
            currentAccountState = .OldDeviceDeactivatedAccount
        case (false, false):
            currentAccountState = .NewDeviceNewAccount
        case (true, false):
            currentAccountState = .NewDeviceNewAccount 
        }
        
        ZMUserSession.addInitalSyncCompletionObserver(self)
        self.authenticationToken = ZMUserSessionAuthenticationNotification.addObserverWithBlock({ [weak self] (note) in
            switch note.type {
            case .AuthenticationNotificationAuthenticationDidSuceeded:
                self?.didAuthenticate()
            case .AuthenticationNotificationAuthenticationDidFail:
                self?.failedToAuthenticate()
            default:
                return
            }
        })
        
        self.registrationToken = ZMUserSessionRegistrationNotification.addObserverWithBlock({ [weak self] (note) in
            guard note.type == .RegistrationNotificationPhoneNumberVerificationDidSucceed ||
                  note.type == .RegistrationNotificationEmailVerificationDidSucceed,
                  let strongSelf = self
            else { return }
            
            strongSelf.didRegister = true
        })
    }
    
    deinit {
        ZMUserSession.removeInitalSyncCompletionObserver(self)
        ZMUserSessionAuthenticationNotification.removeObserver(authenticationToken)
        ZMUserSessionRegistrationNotification.removeObserver(registrationToken)
    }

}