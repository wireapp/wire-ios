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

@objcMembers
final class NativePushChannel: NSObject, PushChannelType {
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

    var keepOpen = false {
        didSet {
            if keepOpen {
                scheduleOpen()
            } else {
                close()
            }
        }
    }

    var canOpenConnection: Bool {
        keepOpen && websocketURL != nil && consumer != nil
    }

    let environment: BackendEnvironmentProvider
    var session: URLSession?
    let scheduler: ZMTransportRequestScheduler
    var websocketTask: URLSessionWebSocketTask?
    weak var consumer: ZMPushChannelConsumer?
    var consumerQueue: GroupQueue?
    var workQueue: OperationQueue
    var pingTimer: ZMTimer?
    private let minTLSVersion: TLSVersion

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
        self.workQueue = queue
        self.proxyUsername = proxyUsername
        self.proxyPassword = proxyPassword
        self.minTLSVersion = TLSVersion.minVersionFrom(minTLSVersion)
        super.init()

        let sessionConfig = URLSessionConfiguration.ephemeral
        sessionConfig.tlsMinimumSupportedProtocolVersion = self.minTLSVersion.secValue

        if let settings = environment.proxy?
            .socks5Settings(proxyUsername: proxyUsername, proxyPassword: proxyPassword) {
            sessionConfig.httpShouldUsePipelining = true
            sessionConfig.connectionProxyDictionary = settings
        }

        self.session = URLSession(configuration: sessionConfig, delegate: self, delegateQueue: queue)
    }

    func close() {
        WireLogger.pushChannel.info("Push channel was closed")

        scheduler.performGroupedBlock { [weak self] in
            self?.websocketTask?.cancel()
            self?.onClose()
        }
    }

    func reachabilityDidChange(_ reachability: ReachabilityProvider) {
        let didGoOnline = reachability.mayBeReachable && !reachability.oldMayBeReachable
        guard didGoOnline else { return }

        scheduleOpen()
    }

    func setPushChannelConsumer(_ consumer: ZMPushChannelConsumer?, queue: GroupQueue) {
        consumerQueue = queue
        self.consumer = consumer

        if consumer == nil {
            close()
        } else {
            scheduleOpen()
        }
    }

    func open() {
        guard
            keepOpen,
            websocketTask == nil,
            let accessToken,
            let websocketURL
        else {
            return
        }

        var connectionRequest = URLRequest(url: websocketURL)
        connectionRequest.setValue("\(accessToken.type) \(accessToken.token)", forHTTPHeaderField: "Authorization")

        websocketTask = session?.webSocketTask(with: connectionRequest)
        websocketTask?.resume()
    }

    func scheduleOpen() {
        scheduler.performGroupedBlock { [weak self] in
            self?.scheduleOpenInternal()
        }
    }

    private func scheduleOpenInternal() {
        guard canOpenConnection else {
            WireLogger.pushChannel.debug("Conditions for scheduling opening not fulfilled, waiting...")
            return
        }
        WireLogger.pushChannel.debug("Schedule opening..")
        scheduler.add(ZMOpenPushChannelRequest())
    }

    var websocketURL: URL? {
        guard let clientID else { return nil }

        let url = environment.backendWSURL.appendingPathComponent("/await")
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
        urlComponents?.queryItems = [URLQueryItem(name: "client", value: clientID)]

        return urlComponents?.url
    }

    func listen() {
        websocketTask?.receive(completionHandler: { [weak self] result in
            switch result {
            case let .failure(error):
                WireLogger.pushChannel.debug("Failed to receive message \(error)")
                self?.onClose()

            case let .success(message):
                guard case let .data(data) = message else {
                    break
                }

                self?.consumerQueue?.performGroupedBlock {
                    self?.consumer?.pushChannelDidReceive(data)
                }
            }

            self?.listen()
        })
    }

    // MARK: - Private

    private let proxyUsername: String?
    private let proxyPassword: String?

    private func onClose() {
        websocketTask = nil
        stopPingTimer()

        consumerQueue?.performGroupedBlock {
            self.consumer?.pushChannelDidClose()
        }

        if keepOpen {
            scheduleOpen()
        }
    }

    private func onOpen() {
        listen()
        startPingTimer()

        consumerQueue?.performGroupedBlock {
            self.consumer?.pushChannelDidOpen()
        }
    }

    private func stopPingTimer() {
        pingTimer?.cancel()
        pingTimer = nil
    }

    private func schedulePingTimer() {
        stopPingTimer()
        startPingTimer()
    }

    private func startPingTimer() {
        let timer = ZMTimer(target: self, operationQueue: workQueue)
        timer?.fire(afterTimeInterval: 30)
        pingTimer = timer
    }
}

extension NativePushChannel: ZMTimerClient {
    func timerDidFire(_: ZMTimer!) {
        WireLogger.pushChannel.debug("Sending ping")
        websocketTask?.sendPing(pongReceiveHandler: { error in
            if let error {
                WireLogger.pushChannel.debug("Failed to send ping: \(error)")
            }
        })
        schedulePingTimer()
    }
}

extension NativePushChannel: URLSessionWebSocketDelegate {
    func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didOpenWithProtocol protocol: String?
    ) {
        WireLogger.pushChannel.info("Push channel did open with protocol \(`protocol` ?? "n/a")")

        onOpen()
    }

    func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
        reason: Data?
    ) {
        WireLogger.pushChannel.info("Push channel did close with code \(closeCode), reason: \(reason ?? Data())")

        onClose()
    }
}

extension NativePushChannel: URLSessionDataDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        WireLogger.pushChannel
            .error("Websocket open connection task did fail: \(error.map { String(describing: $0) } ?? "n/a")")

        websocketTask = nil
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        let protectionSpace = challenge.protectionSpace

        guard protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust else {
            return completionHandler(.performDefaultHandling, challenge.proposedCredential)
        }

        if let serverTrust = protectionSpace.serverTrust,
           environment.verifyServerTrust(trust: serverTrust, host: protectionSpace.host) {
            return completionHandler(.performDefaultHandling, challenge.proposedCredential)
        } else {
            return completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}
