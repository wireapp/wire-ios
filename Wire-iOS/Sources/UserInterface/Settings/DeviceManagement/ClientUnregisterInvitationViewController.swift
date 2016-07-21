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


import UIKit
import Cartography

class ClientUnregisterInvitationViewController: RegistrationStepViewController {
    var heroLabel : UILabel?
    var subtitleLabel : UILabel?
    var manageDevicesButton : UIButton?
    var signOutButton : UIButton?
    var containerView : UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        self.createContainerView()
        self.createHeroLabel()
        self.createSubtitleLabel()
        self.createDeleteDevicesButton()
        self.createSignOutButton()
        self.createConstraints()
    }
    
    private func createContainerView() {
        let view = UIView()
        self.containerView = view
        self.view?.addSubview(view)
    }
  
    private func createHeroLabel() {
        let heroLabel = UILabel()
        heroLabel.translatesAutoresizingMaskIntoConstraints = false
        heroLabel.font = UIFont(magicIdentifier: "style.text.large.font_spec_medium")
        heroLabel.textColor = UIColor(magicIdentifier: "style.color.static_foreground.normal")
        heroLabel.numberOfLines = 0
        heroLabel.text = String(format:NSLocalizedString("registration.signin.too_many_devices.title", comment:""), ZMUser.selfUser().displayName)
        
        self.heroLabel = heroLabel
        self.containerView?.addSubview(heroLabel)
    }
    
    private func createSubtitleLabel() {
        let subtitleLabel = UILabel()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.font = UIFont(magicIdentifier: "style.text.large.font_spec_light")
        subtitleLabel.textColor = UIColor(magicIdentifier: "style.color.static_foreground.normal")
        subtitleLabel.numberOfLines = 0
        subtitleLabel.text = NSLocalizedString("registration.signin.too_many_devices.subtitle", comment:"")
        
        self.subtitleLabel = subtitleLabel
        self.containerView?.addSubview(subtitleLabel)
    }
    
    private func createDeleteDevicesButton() {
        let manageDevicesButton = Button(style: .FullMonochrome)
        manageDevicesButton.setTitle(NSLocalizedString("registration.signin.too_many_devices.manage_button.title", comment:""), forState: UIControlState.Normal)
        manageDevicesButton.addTarget(self, action: #selector(ClientUnregisterInvitationViewController.openManageDevices(_:)), forControlEvents: .TouchUpInside)
        self.manageDevicesButton = manageDevicesButton
        self.containerView?.addSubview(manageDevicesButton)
    }
    
    private func createSignOutButton() {
        let signOutButton = Button(styleClass: "dialogue-button-empty-monochrome")
        signOutButton.setTitle(NSLocalizedString("registration.signin.too_many_devices.sign_out_button.title", comment:""), forState: UIControlState.Normal)
        signOutButton.addTarget(self, action: #selector(ClientUnregisterInvitationViewController.signOut(_:)), forControlEvents: .TouchUpInside)
        signOutButton.hidden = true // for the moment not supported
        self.signOutButton = signOutButton
        self.containerView?.addSubview(signOutButton)
    }
    
    private func createConstraints() {
        if let containerView = self.containerView,
            let subtitleLabel = self.subtitleLabel,
            let heroLabel = self.heroLabel,
            let manageDevicesButton = self.manageDevicesButton,
            let signOutButton = self.signOutButton {
                
                constrain(self.view, containerView) { selfView, containerView in
                    containerView.edges == selfView.edges ~ 900
                    containerView.width <= 414
                    containerView.height <= 736
                    containerView.center == selfView.center
                }
                
                constrain(containerView, subtitleLabel, heroLabel) { containerView, subtitleLabel, heroLabel in
                    heroLabel.left == containerView.left + 28
                    heroLabel.right == containerView.right - 28
                    subtitleLabel.left == containerView.left + 28
                    subtitleLabel.right == containerView.right - 28
                    subtitleLabel.top == heroLabel.bottom
                }
                
                constrain(subtitleLabel, manageDevicesButton) { subtitleLabel, manageDevicesButton in
                    manageDevicesButton.top == subtitleLabel.bottom + 24
                }
                
                constrain(containerView, manageDevicesButton, signOutButton) { containerView, manageDevicesButton, signOutButton in
                    manageDevicesButton.left == containerView.left + 24
                    manageDevicesButton.right == containerView.right - 24
                    manageDevicesButton.bottom == signOutButton.top - 24
                    manageDevicesButton.height == 40
                    
                    signOutButton.left == containerView.left + 24
                    signOutButton.right == containerView.right - 24
                    signOutButton.bottom == containerView.bottom
                    signOutButton.height == 0
                }
        }
    }
    
    // MARK: - Actions
    
    func openManageDevices(sender : UIButton!) {
        if let formStepDelegate = self.formStepDelegate {
            formStepDelegate.didCompleteFormStep(self)
        }
    }
    
    func signOut(sender : UIButton!) {
        // for the moment not supported
    }
}
