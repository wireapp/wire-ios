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
import ObjectiveC
import WireExtensionComponents
import zshare
import Classy

class ShareViewController: UIViewController, UIScrollViewDelegate, UITextViewDelegate, TokenFieldDelegate, ConversationListViewControllerDelegate {

    
    // MARK: - Outlets
    @IBOutlet private weak var previewImageContainerView: UIView!
    @IBOutlet private weak var messageTextView: TextView!
    @IBOutlet private weak var messageTextBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var messageTextHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var urlLabel: UILabel!
    @IBOutlet private weak var urlContainerView: UIView!
    @IBOutlet private weak var URLContainerSeparatorView: UIView!
    @IBOutlet private weak var urlContainerHeight: NSLayoutConstraint!
    @IBOutlet private weak var imageContainerWidth: NSLayoutConstraint!
    
    @IBOutlet private weak var recipientsTokenField : TokenField!
    
    @IBOutlet private weak var searchingView: UIView!
    @IBOutlet private weak var messageView: UIScrollView!
    @IBOutlet private weak var doneButton: IconButton!
    @IBOutlet private weak var cancelButton: IconButton!
    
    private var previewImagesController: PreviewImagesViewController! = nil
    private var conversationListController: ConversationListViewController! = nil
    
    // MARK: - UIViewController overrides
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardDidChangeFrameNotification, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var barButtonOffset: CGFloat = 0
        if self.traitCollection.userInterfaceIdiom == .Pad {
            barButtonOffset = 4
            self.navigationController?.view.layer.cornerRadius = 5
            self.navigationController?.view.clipsToBounds = true
        } else {
            barButtonOffset = 8
        }

        self.doneButton.setIcon(.Checkmark, withSize: .Tiny, forState: .Normal)
        self.cancelButton.setIcon(.X, withSize: .Tiny, forState: .Normal)
        
        if let leftItem = self.navigationItem.leftBarButtonItem {
            let leftSpacer = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FixedSpace, target: nil, action: nil)
            leftSpacer.width = barButtonOffset
            self.navigationItem.leftBarButtonItems = [leftSpacer, leftItem]
        }
        
        if let rightItem = self.navigationItem.rightBarButtonItem {
            let rightSpacer = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FixedSpace, target: nil, action: nil)
            rightSpacer.width = barButtonOffset
            self.navigationItem.rightBarButtonItems = [rightSpacer, rightItem]
        }
        
        self.navigationItem.backBarButtonItem?.title = ""
        
        let image = UIImage(forLogoWithColor: UIColor.accentColor, iconSize: .Medium)
        self.navigationItem.titleView = UIImageView(image: image)
        
        self.recipientsTokenField.accessoryButton.setImage(UIImage(forIcon: .Plus, iconSize: .Tiny, color: UIColor.blackColor()), forState: .Normal)
        self.recipientsTokenField.accessoryButton.cas_styleClass = "dark"
        self.recipientsTokenField.accessoryButton.addTarget(self, action: "addRecipientPressed:", forControlEvents: .TouchUpInside)
        
        self.recipientsTokenField.toLabelText = NSLocalizedString("sharing-ext.toLabelText", comment:"String for 'To:' label in view with recipients bubles")
        self.messageTextView.placeholder = NSLocalizedString("sharing-ext.message.placeholder", comment:"Placeholder text for user message")

        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateMessageHeight:", name: UIKeyboardDidChangeFrameNotification, object: nil)
        
        self.imageContainerWidth.constant = self.previewImagesController.previewImageSize
        
        self.isSearching = false
        
        self.setupUIFromContext(self.extensionContext!)

        let environment: BackendEnvironment
        switch NSUserDefaults.sharedUserDefaults().stringForKey("ZMBackendEnvironmentType") {
        case .Some("staging"): environment = .Staging
        case .Some("edge"): environment = .Edge
        default: environment = .Production
        }

        self.shareExtensionAPI = ShareExtensionAPI(backend: Backend(env: environment))

        self.shareExtensionAPI.login { (user: User?, errorOptional: NSError?) -> () in
            if let error = errorOptional {
                let alert = UIAlertController(error: error, context: self.extensionContext!) {
                    self.cancelWithError(error)
                }
                self.presentViewController(alert, animated: true, completion: nil)
            } else {
                self.currentUser = user;
            }
        }
        
        
        SharedAnalytics.sharedInstance().tagEvent(AnalyticsEvent.Opened, attributes:
            [.numberOfImages(self.extensionContext?.imageItemProviders().count ?? 0),
             .hasURL(self.extensionContext?.urlItemProvider() != nil),
             .hasText(self.extensionContext?.plainTextItemProvider() != nil)])
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.updateDoneButton()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        self.recipientsTokenField.becomeFirstResponder()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if (self.imagesToSend.count > 0) {
            let rect = self.messageTextView.convertRect(self.previewImageContainerView.frame, fromView: self.previewImageContainerView.superview)
            let path = UIBezierPath(rect: rect)
            self.messageTextView.textContainer.exclusionPaths = [path]
        }
    }

    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
    }
    
    override func willTransitionToTraitCollection(newCollection: UITraitCollection, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransitionToTraitCollection(newCollection, withTransitionCoordinator: coordinator)
        
        switch newCollection.verticalSizeClass  {
        case .Compact:
            self.recipientsTokenField.cas_styleClass = "compact"
            if let navigationBar = self.navigationController?.navigationBar as? FlexibleNavigationBar {
                navigationBar.height = 44                
            }
        case .Regular, .Unspecified:
            self.recipientsTokenField.cas_styleClass = "regular"
            if let navigationBar = self.navigationController?.navigationBar as? FlexibleNavigationBar {
                navigationBar.height = 60
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Model
    
    private var shareExtensionAPI: ShareExtensionAPI! = nil {
        didSet {
            if let conversationListController = self.conversationListController {
                conversationListController.shareExtensionAPI = self.shareExtensionAPI
            }
        }
    }
    
    private var currentUser: User? = nil {
        didSet {
            if let accentColor = self.currentUser?.accentColor {
                UIColor.setAccentColor(accentColor)
                CASStyler.defaultStyler().applyDefaultColorSchemeWithAccentColor(UIColor.accentColor)
                
                let image = UIImage(forLogoWithColor: UIColor.accentColor, iconSize: .Medium)
                self.navigationItem.titleView = UIImageView(image: image)
            
                self.view.cas_setNeedsUpdateStylingForSubviews()
            }
        }
    }
    
    
    // MARK: Data
    
    private var imagesToSend: Array<ImageMessage> = [] {
        didSet {
            self.updateDoneButton()
        }
    }
    private var messageToSend: String? = nil {
        didSet {
            self.updateDoneButton()
        }
    }
    private var urlToSend: NSURL? = nil {
        didSet {
            self.updateDoneButton()
        }
    }
    
    private var recipientList = Array<Conversation>()
    
    // MARK: Recipients
    
    // MARK: State
    private var isSearching: Bool = false {
        didSet {
            self.messageView.hidden = self.isSearching
            self.searchingView.hidden = !self.isSearching
        }
    }
    
    var hasContentToSend: Bool {
            return (self.imagesToSend.count > 0) || (self.messageToSend != nil && (self.messageToSend!).characters.count > 0) || (self.urlToSend != nil)
    }
    
    var isReadyToSend: Bool {
        return self.hasContentToSend && (self.recipientList.count > 0)
    }
    
    var sendingStarted: Bool = false
    
    private func setupUIFromContext(context: NSExtensionContext) {
        let imageAttachments = context.imageItemProviders()
        if imageAttachments.count > 0 {
            self.setupViewsForImageAttachmentsWithCount(imageAttachments.count)
            self.loadPreviewImagesForImageAttachments(imageAttachments)
        } else {
            self.hidePreviewImageViews()
        }
        
        let showURLClosure: Void -> Void = {
            if let urlAttachment = context.urlItemProvider() {
                urlAttachment.loadURL() { (url: NSURL) -> Void in
                    self.urlToSend = url
                    self.setupViewsForURL(url)
                }
            } else {
                self.hideURLViews()
            }
        }
        
        if let textAttachment = context.plainTextItemProvider() {
            textAttachment.loadText() { (text: String) -> Void in
                self.messageToSend = text
                self.setupViewsForText(text)
                
                if !text.containsURL() {
                    showURLClosure()
                } else {
                    self.hideURLViews()
                }
            }
        } else {
            showURLClosure()
        }
    }

    
    private func hideURLViews() {
        self.urlLabel.text = ""
        self.messageTextHeightConstraint.constant += self.urlContainerHeight.constant
        self.urlContainerHeight.active = false
        self.URLContainerSeparatorView.hidden = true
        self.urlContainerView.hidden = true
    }
    
    private func hidePreviewImageViews() {
        self.previewImageContainerView.hidden = true
    }
    
    private func setupViewsForImageAttachmentsWithCount(count:Int) {
        self.previewImagesController.numberOfPreviewImages = count
        
        self.messageTextView.text = ""
        self.messageTextView.superview?.sendSubviewToBack(self.messageTextView)
        self.view.layoutIfNeeded()
    }
    
    private func setupViewsForURL(url: NSURL) {
        self.messageTextView.text = ""
        self.messageTextView.superview?.sendSubviewToBack(self.messageTextView)
        self.urlLabel.text = url.absoluteString
        
        self.view.layoutIfNeeded()
    }
    
    private func setupViewsForText(text: String) {
        let options = [
            NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
            NSCharacterEncodingDocumentAttribute: NSUTF8StringEncoding
        ] as [String : AnyObject]
        if let string = try? NSMutableAttributedString(data: text.dataUsingEncoding(NSUTF8StringEncoding)!, options: options, documentAttributes: nil),
            font = self.messageTextView.font {
                let attributes = [NSFontAttributeName: font]
                string.setAttributes(attributes, range: NSMakeRange(0, string.length))
                self.messageTextView.attributedText = string
        }
    }
    
    private func loadPreviewImagesForImageAttachments(imageAttachments: Array<NSItemProvider>) {
        for var i = 0; i < imageAttachments.count; i++ {
            let attachment = imageAttachments[i]
            let index = i
            let imagePixelSize = self.previewImagesController.previewImageSize * self.traitCollection.displayScale
            
            attachment.loadImage() { (object: NSSecureCoding) -> Void in
                
                if let imageURL = object as? NSURL {
                    self.imagesToSend.append(ImageMessage(url:imageURL))
                    self.updateDoneButton()
                    
                    UIImage.loadPreviewForImageWithURL(imageURL, maxPixelSize:Int(imagePixelSize)) { (previewImage: UIImage?) -> Void in
                        self.previewImagesController.setImage(previewImage, forPreviewAtIndex: index)
                    }
                } else if let image = object as? UIImage,
                    imageData = UIImagePNGRepresentation(image) {
                        self.imagesToSend.append(ImageMessage(data: imageData, imageSize: image.size))
                        
                        let previewOptions = [NSItemProviderPreferredImageSizeKey: NSValue(CGSize: CGSizeMake(imagePixelSize, imagePixelSize))]
                        attachment.loadPreviewImageWithOptions(previewOptions) { (object: NSSecureCoding?, error: NSError!) -> Void in
                            dispatch_async(dispatch_get_main_queue()) {
                                if let previewImage = object as? UIImage {
                                    self.previewImagesController.setImage(previewImage, forPreviewAtIndex: index)
                                } else {
                                    self.previewImagesController.setImage(image, forPreviewAtIndex: index)
                                }
                            }
                        }
                }
            }
        }
    }
    
    private func updateDoneButton() {
        self.doneButton.enabled = self.isReadyToSend  && !self.sendingStarted
    }
    
    func updateMessageHeight(note: NSNotification?) {
        if let frameValue = note?.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue {
            let rect = self.view.convertRect(frameValue.CGRectValue(), fromView: self.view.window)
            let value = self.view.frame.height - CGRectGetMinY(rect)
            self.messageTextBottomConstraint.constant = (value > 0) ? value : 0
        }
        
        let messageHeight = self.messageTextView.contentSize.height +
            self.messageTextView.textContainerInset.top + self.messageTextView.textContainerInset.bottom
        self.messageTextHeightConstraint.constant = messageHeight
        self.messageTextView.contentOffset = CGPointZero
        self.view.layoutIfNeeded()
        
        if (self.messageTextView.isFirstResponder() &&
            self.messageView.contentSize.height > self.messageView.frame.height) {
            self.messageView.setContentOffset(CGPointMake(0, self.messageView.contentSize.height - self.messageView.frame.height), animated: true)
        } else {
            self.messageView.setContentOffset(CGPointZero, animated: false)
        }
    }
    
    // MARK: - Navigation and Actions

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let controller = segue.destinationViewController as? ConversationListViewController {
            controller.shareExtensionAPI = self.shareExtensionAPI
            controller.delegate = self
            if segue.identifier == "searchForConversations" {
                controller.tableView.cas_styleClass = "embed"
                self.conversationListController = controller
            } else if segue.identifier == "modalSearchForConversations" {
                controller.tableView.cas_styleClass = "pushed"
                controller.excludedConversations = self.recipientList
            }
        } else if let controller = segue.destinationViewController as? PreviewImagesViewController {
            if segue.identifier == "embed-preview-images" {
                self.previewImagesController = controller
            }
        }
    }
    
    @IBAction func unwindFromSegue(segue: UIStoryboardSegue) {
        
    }
    
    @IBAction func addRecipientPressed(sender: AnyObject) {
        self.performSegueWithIdentifier("modalSearchForConversations", sender: sender)
    }

    @IBAction func cancelPressed(sender: AnyObject) {
        self.cancelWithError(NSError(domain: ShareDomain, code: NSUserCancelledError, userInfo: nil))
    }
    
    @IBAction func donePressed(sender: AnyObject) {
        self.complete()
        self.updateDoneButton()
    }
    
    func cancelWithError(error: NSError) {
        var cancelReason = ""
        if error.code == NSUserCancelledError {
            cancelReason = "userCanceled"
        } else if error.domain == ShareDomain {
            cancelReason = "unauthorized"
        }
        
        SharedAnalytics.sharedInstance().tagEvent(AnalyticsEvent.Closed, attributes: [
            .numberOfImages(self.imagesToSend.count),
            .hasURL(self.urlToSend != nil),
            .hasText(self.messageToSend != nil),
            .numberOfRecipients(self.recipientList.count),
            .cancel(cancelReason),
            ]
        )
        
        self.extensionContext!.cancelRequestWithError(error)
    }
    
    func complete() {
        var dispatchOnceToken: dispatch_once_t = 0
        dispatch_once(&dispatchOnceToken) {
            self.sendingStarted = true
            if let navigationController = self.navigationController {
                navigationController.showLoadingView = true
            } else {
                self.showLoadingView = true
            }
            self.messageTextView.resignFirstResponder()
            self.recipientsTokenField.resignFirstResponder()
            self.cancelButton.enabled = false
            
            var textMessage: TextMessage? = nil
            if let url = self.urlToSend {
                textMessage = TextMessage(url: url, message: self.messageToSend)
            } else if let text = self.messageToSend {
                textMessage = TextMessage(text: text)
            }
            
            let storeAnalyticsClosure: () -> () = {
                let numberOfGroupRecipients = self.recipientList.reduce(0) { (sum: Int, recipient:Conversation) -> Int in
                    return sum + ((recipient.type == ConversationType.Group) ? 1 : 0)
                }
                
                SharedAnalytics.sharedInstance().tagEvent(AnalyticsEvent.Closed, attributes: [
                    .numberOfImages(self.imagesToSend.count),
                    .hasURL(self.urlToSend != nil),
                    .hasText(self.messageToSend != nil),
                    .numberOfRecipients(self.recipientList.count),
                    .numberOfGroupRecipients(numberOfGroupRecipients),
                    .numberOfOneOnOneRecipients(self.recipientList.count - numberOfGroupRecipients),
                    .cancel("no")
                    ]
                )
            }
            
            let completionClosure: () -> () = {
                dispatch_async(dispatch_get_main_queue()) {
                    self.extensionContext?.completeRequestReturningItems([], completionHandler: nil)
                    self.showLoadingView = false
                }
            }
            
            let sendImagesClosure: (completion:()->()) -> () = { (completion:()->()) in
                if self.imagesToSend.count > 0 {
                    self.shareExtensionAPI.postImages(self.imagesToSend, toConversations: self.recipientList) {
                        (error: NSError?) -> () in
                        completion()
                    }
                } else {
                    completion()
                }
            }
            
            let sendTextMessageClosure: (comletion:()->()) -> () = { (completion:()->()) in
                if let message = textMessage {
                    self.shareExtensionAPI.postMessage(message, toConversations: self.recipientList) {
                        (error: NSError?) -> Void in
                        completion()
                    }
                } else {
                    completion()
                }
            }
            
            sendImagesClosure() {
                sendTextMessageClosure() {
                    storeAnalyticsClosure()
                    completionClosure()
                }
            }
        }
    }
    
    // MARK: - UITextViewDelegate
    
    func textViewDidBeginEditing(textView: UITextView) {
        if textView == self.messageTextView {
            self.recipientsTokenField.resignFirstResponder()
            if (self.recipientList.count > 1) {
                self.recipientsTokenField.setCollapsed(true, animated: true)
            }
        }
    }
    
    func textViewDidChange(textView: UITextView) {
        if textView == self.messageTextView {
            self.updateMessageHeight(nil)
            self.messageToSend = textView.text
        }
    }

    // MARK: - TokenFieldDelegate
    
    func tokenField(tokenField: TokenField!, changedTokensTo tokens: [AnyObject]!) {        
        self.recipientList = tokens.map { (($0 as! Token).representedObject as! Conversation) }
        self.conversationListController.excludedConversations = self.recipientList
        self.updateDoneButton()
    }
    
    func tokenField(tokenField: TokenField!, changedFilterTextTo text: String!) {
        self.isSearching = text.characters.count > 0
        self.conversationListController.searchTerm = text
    }
    
    func tokenFieldStringForCollapsedState(tokenField: TokenField!) -> String! {
        if (self.recipientList.count > 1) {
            return NSString.localizedStringWithFormat(NSLocalizedString("sharing-ext.recipients-field.collapsed", comment: "Name of first user + number of others more"),
                self.recipientList[0].displayName, self.recipientList.count-1) as String
        } else if (self.recipientList.count > 0) {
            return self.recipientList[0].displayName
        } else {
            return ""
        }
    }

    // MARK: - ConversationListViewControllerDelegate
    
    func conversationList(conversationList: ConversationListViewController, didSelectConversation conversation: Conversation) {
        self.recipientList.append(conversation)
        self.recipientsTokenField.addTokenForTitle(conversation.displayName, representedObject: conversation)
        self.isSearching = false
        
        conversationList.searchTerm = ""
        conversationList.excludedConversations = self.recipientList
        self.conversationListController.searchTerm = ""
        self.conversationListController.excludedConversations = self.recipientList
        
        self.updateDoneButton()
    }
    
}
