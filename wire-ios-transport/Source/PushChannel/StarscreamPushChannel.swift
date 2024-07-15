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

import Foundation
import Starscream

@objcMembers
final class StarscreamPushChannel: NSObject, PushChannelType {

    var webSocket: WebSocket?
    var workQueue: OperationQueue
    let environment: BackendEnvironmentProvider
    let scheduler: ZMTransportRequestScheduler
    weak var consumer: ZMPushChannelConsumer?
    var consumerQueue: GroupQueue?
    var pingTimer: ZMTimer?
    private let minTLSVersion: TLSVersion

    var clientID: String? {
        didSet {
            WireLogger.pushChannel.debug("Setting client ID")
            scheduleOpen()
        }
    }

    var accessToken: AccessToken? {
        didSet {
            WireLogger.pushChannel.debug("Setting access token")
        }
    }

    var keepOpen: Bool = false {
        didSet {
            if keepOpen {
                scheduleOpen()
            } else {
                self.close()
            }
        }
    }

    var canOpenConnection: Bool {
        return keepOpen && websocketURL != nil && consumer != nil
    }

    var websocketURL: URL? {
        guard let clientID else { return nil }

        let url = environment.backendWSURL.appendingPathComponent("/await")
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
        urlComponents?.queryItems = [URLQueryItem(name: "client", value: clientID)]

        return urlComponents?.url
    }

    required init(
        scheduler: ZMTransportRequestScheduler,
        userAgentString: String,
        environment: BackendEnvironmentProvider,
        proxyUsername: String?,
        proxyPassword: String?,
        minTLSVersion: String?,
        queue: OperationQueue
    ) {
        self.environment = environment
        self.scheduler = scheduler
        self.proxyUsername = proxyUsername
        self.proxyPassword = proxyPassword
        self.workQueue = queue
        self.minTLSVersion = TLSVersion.minVersionFrom(minTLSVersion)
    }

    func reachabilityDidChange(_ reachability: ReachabilityProvider) {
        WireLogger.backend.debug("reachability did change. May be reachable: \(reachability.mayBeReachable), is mobile connection: \(reachability.isMobileConnection)")

        let didGoOnline = reachability.mayBeReachable && !reachability.oldMayBeReachable

        guard didGoOnline else { return }
        WireLogger.backend.debug("reachability did change. didGoOnline", attributes: .safePublic)

        scheduleOpen()
    }

    func setPushChannelConsumer(_ consumer: ZMPushChannelConsumer?, queue: GroupQueue) {
        self.consumerQueue = queue
        self.consumer = consumer

        if consumer == nil {
            close()
        } else {
            scheduleOpen()
        }
    }

    func close() {
        WireLogger.pushChannel.info("Push channel was closed")

        scheduler.performGroupedBlock {
            self.webSocket?.disconnect()
        }
    }

    func open() {
        guard
            keepOpen,
            webSocket == nil,
            let accessToken,
            let websocketURL
        else {
            WireLogger.pushChannel.warn("Can't connect websocket")
            return
        }

        var connectionRequest = URLRequest(url: websocketURL)
        connectionRequest.setValue("\(accessToken.type) \(accessToken.token)", forHTTPHeaderField: "Authorization")

        let certificatePinning = StarscreamCertificatePinning(environment: environment)

        webSocket = WebSocket(
            request: connectionRequest,
            certPinner: certificatePinning,
            useCustomEngine: environment.proxy == nil,
            minTLSVersion: minTLSVersion.starscreamValue
        )

        webSocket?.delegate = self

        if let proxySettings = environment.proxy {
            let proxyDictionary = proxySettings.socks5Settings(proxyUsername: proxyUsername, proxyPassword: proxyPassword)

            let configuration = URLSessionConfiguration.default
            configuration.connectionProxyDictionary = proxyDictionary
            configuration.httpShouldUsePipelining = true

            webSocket?.configuration = configuration
        }

        if let queue = workQueue.underlyingQueue {
            webSocket?.callbackQueue = queue
        }
        webSocket?.connect()

        let attributes: LogAttributes = [
            .selfClientId: clientID?.redactedAndTruncated(maxVisibleCharacters: 3, length: 8)
        ]
        WireLogger.pushChannel.info("Connecting websocket with URL: \(websocketURL.endpointRemoteLogDescription)",
                                    attributes: attributes, .safePublic)
    }

    func scheduleOpen() {
        scheduler.performGroupedBlock { [weak self] in
            self?.scheduleOpenInternal()
        }
    }

    // MARK: - Private

    private let proxyUsername: String?
    private let proxyPassword: String?

    private func scheduleOpenInternal() {
        guard canOpenConnection else {
            WireLogger.pushChannel.debug("Conditions for scheduling opening not fulfilled, waiting...")
            return
        }
        WireLogger.pushChannel.debug("Schedule opening..")
        scheduler.add(ZMOpenPushChannelRequest())
    }

    fileprivate func onClose() {
        webSocket = nil
        stopPingTimer()

        consumerQueue?.performGroupedBlock {
            self.consumer?.pushChannelDidClose()
        }

        if keepOpen {
            scheduleOpen()
        }
    }

    fileprivate func onOpen() {
        startPingTimer()

        consumerQueue?.performGroupedBlock({
            self.consumer?.pushChannelDidOpen()
        })
    }

    private func stopPingTimer() {
        pingTimer?.cancel()
        pingTimer = nil
    }

    fileprivate func schedulePingTimer() {
        stopPingTimer()
        startPingTimer()
    }

    fileprivate func startPingTimer() {
        let timer = ZMTimer(target: self, operationQueue: workQueue)
        timer?.fire(afterTimeInterval: 30)
        pingTimer = timer
    }

}

extension StarscreamPushChannel: ZMTimerClient {

    func timerDidFire(_ timer: ZMTimer!) {
        WireLogger.pushChannel.debug("Sending ping")
        webSocket?.write(ping: Data())
        schedulePingTimer()
    }

}

extension StarscreamPushChannel: WebSocketDelegate {
    func didReceive(event: WebSocketEvent, client: WebSocketClient) {
        switch event {

        case .connected:
            WireLogger.pushChannel.debug("Sending ping")
            onOpen()
        case .disconnected:
            WireLogger.pushChannel.debug("Websocket disconnected")
            onClose()
        case .text:
            break
        case .binary(let data):
            WireLogger.pushChannel.debug("Received data")
            consumerQueue?.performGroupedBlock { [weak self] in
                self?.consumer?.pushChannelDidReceive(data)
            }
        case .pong:
            break
        case .ping:
            break
        case .error:
            onClose()
        case .viabilityChanged:
            break
        case .reconnectSuggested:
            break
        case .cancelled:
            onClose()
        case .peerClosed:
            onClose()
        }
    }

}

final class StarscreamCertificatePinning: CertificatePinning {

    let environment: BackendEnvironmentProvider

    init(environment: BackendEnvironmentProvider) {
        self.environment = environment
    }

    func evaluateTrust(trust: SecTrust, domain: String?, completion: ((PinningState) -> Void)) {
        if environment.verifyServerTrust(trust: trust, host: domain) {
            completion(.success)
        } else {
            completion(.failed(nil))
        }
    }

}

private extension TLSVersion {

    var starscreamValue: Starscream.TLSVersion {
        switch self {
        case .v1_2:
            return .v1_2

        case .v1_3:
            return .v1_3
        }
    }

}
