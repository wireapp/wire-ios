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

import SwiftUI
import UIKit
import Social
import UniformTypeIdentifiers
import WireCommonComponents
import WireDataModel
import WireDomain
import WireShareEngine
import WireShareExtensionCore

/// The main view controller for the Koi Share Extension.
/// Handles extraction of shared content and presents the main node graph.
class ShareViewController: UIViewController {

    private var shareItems: [ShareItem] = []
    private var hostingController: UIHostingController<RootNode>?

    private var accountManager: AccountManager!
    private var sessionsByAccount = [WireDataModel.Account: SharingSession]()

    override init(
        nibName nibNameOrNil: String?,
        bundle nibBundleOrNil: Bundle?
    ) {
        super.init(
            nibName: nibNameOrNil,
            bundle: nibBundleOrNil
        )

        setUpAccountManager()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        Task {
            await extractSharedContent()
            presentShareUI()
        }
    }

    private func setUpAccountManager() {
        guard
            let currentAppVersion = Bundle.main.shortVersionString,
            let applicationGroupIdentifier = Bundle.main.applicationGroupIdentifier
        else {
            fatalError()
        }

        let sharedContainerURL = FileManager.sharedContainerDirectory(for: applicationGroupIdentifier)
        let accountURLs = AccountURLs(root: sharedContainerURL)

        do {
            accountManager = try AccountManager(
                currentAppVersion: currentAppVersion,
                directory: accountURLs.accounts
            )
        } catch {
            fatalError()
        }
    }

    private func session(for account: WireDataModel.Account) async throws -> SharingSession {
        if let cachedSession = sessionsByAccount[account] {
            return cachedSession
        }

        guard
            let appGroupID = Bundle.main.applicationGroupIdentifier,
            let hostBundleID = Bundle.main.hostBundleIdentifier,
            let bundleInfo = Bundle.main.infoDictionary,
            let buildNumber = bundleInfo[kCFBundleVersionKey as String] as? String
        else {
            fatalError()
        }

        let appContainerURL = FileManager.sharedContainerDirectory(for: appGroupID)

        let loader = try SharingSessionLoader(
            account: account,
            appContainerURL: appContainerURL,
            appGroupID: appGroupID,
            buildNumber: buildNumber,
            sharedUserDefaults: .applicationGroup,
            minTLSVersion: SecurityFlags.minTLSVersion.stringValue
        )

        if DeveloperFlag.simulateMainAppRequiredError.isOn {
            throw SharingSessionLoader.Failure.mainAppRequired(message: "simulated developer flag")
        }

        let session = try await loader.load()
        sessionsByAccount[account] = session
        return session
    }

    // MARK: - Content Extraction
    
    /// Extracts shared content from the extension context.
    private func extractSharedContent() async {
        guard
            let extensionContext = extensionContext,
            let inputItems = extensionContext.inputItems as? [NSExtensionItem],
            !inputItems.isEmpty
        else {
            print("no input items, aborting")
            cancelSharing()
            return
        }
        
        var items: [ShareItem] = []
        
        for inputItem in inputItems {
            guard let attachments = inputItem.attachments else {
                continue
            }

            for attachment in attachments {
                if let item = await extractItem(from: attachment) {
                    items.append(item)
                }
            }
        }

        guard !items.isEmpty else {
            print("no items to share, aborting")
            cancelSharing()
            return
        }

        shareItems = items
    }
    
    /// Extracts a single item from an item provider.
    private func extractItem(from provider: NSItemProvider) async -> ShareItem? {
        // Try image
        if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            print("found image, extracting")
            return await .image(from: provider)
        }
        
        // Try video
        if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
            print("found video, extracting")
            return await .video(from: provider)
        }
        
        // Try generic file
        if provider.hasItemConformingToTypeIdentifier(UTType.data.identifier) {
            print("found data, extracting")
            return await .file(from: provider)
        }
        
        return nil
    }

    // MARK: - UI Presentation
    
    /// Presents the SwiftUI-based node graph.
    private func presentShareUI() {
        let rootNode = RootNode(
            shareItem: shareItems.first!, // TODO: make safe
            onClose: cancelSharing,
            onDone: completeSharing
        )

        let hostingController = UIHostingController(rootView: rootNode)
        self.hostingController = hostingController
        
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.frame = view.bounds
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        hostingController.didMove(toParent: self)
    }
    
    // MARK: - Extension Control

    private func completeSharing() {
        extensionContext?.completeRequest(
            returningItems: nil,
            completionHandler: nil
        )
    }

    private func cancelSharing() {
        let error = NSError(
            domain: "com.johnnguyen.KoiApp.ShareExtension",
            code: 0,
            userInfo: [NSLocalizedDescriptionKey: "Sharing was cancelled"]
        )
        extensionContext?.cancelRequest(withError: error)
    }
    
}
