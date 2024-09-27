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

import avs
import Foundation

// MARK: - FlowManagerType

public protocol FlowManagerType {
    func setVideoCaptureDevice(_ device: CaptureDevice, for conversationId: AVSIdentifier)
}

// MARK: - FlowManager

public class FlowManager: NSObject, FlowManagerType {
    // MARK: Lifecycle

    init(mediaManager: MediaManagerType) {
        super.init()

        self.mediaManager = mediaManager
        self.avsFlowManager = AVSFlowManager(delegate: self, mediaManager: mediaManager)
        NotificationCenter.default.post(name: type(of: self).AVSFlowManagerCreatedNotification, object: self)
    }

    // MARK: Public

    public static let AVSFlowManagerCreatedNotification = Notification.Name("AVSFlowManagerCreatedNotification")

    public func setVideoCaptureDevice(_ device: CaptureDevice, for conversationId: AVSIdentifier) {
        avsFlowManager?.setVideoCaptureDevice(device.deviceIdentifier, forConversation: conversationId.serialized)
    }

    // MARK: Fileprivate

    fileprivate var mediaManager: MediaManagerType?
    fileprivate var avsFlowManager: AVSFlowManager?
}

// MARK: AVSFlowManagerDelegate

extension FlowManager: AVSFlowManagerDelegate {
    public static func logMessage(_: String!) {
        // no-op
    }

    public func request(
        withPath path: String!,
        method: String!,
        mediaType mtype: String!,
        content: Data!,
        context ctx: UnsafeRawPointer!
    ) -> Bool {
        // no-op
        false
    }

    public func didEstablishMedia(inConversation convid: String!) {
        // no-op
    }

    public func didEstablishMedia(inConversation convid: String!, forUser userid: String!) {
        // no-op
    }

    public func setFlowManagerActivityState(_: AVSFlowActivityState) {
        // no-op
    }

    public func networkQuality(_ q: Float, conversation convid: String!) {
        // no-op
    }

    public func mediaWarning(onConversation convId: String!) {
        // no-op
    }

    public func errorHandler(_ err: Int32, conversationId convid: String!, context ctx: UnsafeRawPointer!) {
        // no-op
    }

    public func didUpdateVolume(_ volume: Double, conversationId convid: String!, participantId: String!) {
        // no-op
    }
}
