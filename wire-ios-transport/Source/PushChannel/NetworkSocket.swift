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

// MARK: - NetworkSocketDelegate

@objc
public protocol NetworkSocketDelegate {
    @objc(networkSocketDidOpen:)
    func didOpen(socket: NetworkSocket)

    @objc(didReceiveData:networkSocket:)
    func didReceive(data: Data, on socket: NetworkSocket)

    /// Called when the socket is closed. Might be called from the different queue than `callbackQueue` if the
    /// `NetworkSocket` is torn down when deallocated.
    @objc(networkSocketDidClose:)
    func didClose(socket: NetworkSocket)
}

// MARK: - DataBuffer

@objcMembers
public final class DataBuffer: NSObject {
    // MARK: Public

    public var objcData: __DispatchData {
        data as __DispatchData
    }

    @objc(appendData:)
    public func append(data: __DispatchData) {
        self.data.append(data as DispatchData)
    }

    // MARK: Internal

    func clear(until offset: Int) {
        let dataOffset = data.index(data.startIndex, offsetBy: offset)

        data = data.subdata(in: dataOffset ..< data.endIndex)
    }

    func isEmpty() -> Bool {
        data.isEmpty
    }

    // MARK: Fileprivate

    fileprivate var data = DispatchData.empty

    fileprivate func append(data: DispatchData) {
        self.data.append(data)
    }
}

// MARK: - NetworkSocket

@objcMembers
public final class NetworkSocket: NSObject {
    // MARK: Lifecycle

    public init(
        url: URL,
        trustProvider: BackendTrustProvider,
        delegate: NetworkSocketDelegate?,
        queue: DispatchQueue,
        callbackQueue: DispatchQueue,
        group: ZMSDispatchGroup
    ) {
        self.url = url
        self.trustProvider = trustProvider
        self.delegate = delegate
        self.queue = queue
        self.callbackQueue = callbackQueue
        self.group = group

        queue.setSpecific(key: queueMarkerKey, value: ())

        super.init()
    }

    deinit {
        if state != .stopped {
            if isOnQueue() {
                close(syncDelegate: true)
            } else {
                // `queue` is specially created to handle all the actions on the `networkSocket`.
                // therefore it should be safe to dispatch sync on it: it must not be blocked with other
                // activity.
                queue.sync {
                    close(syncDelegate: true)
                }
            }
        }
    }

    // MARK: Public

    // MARK: - Public API

    public let url: URL
    public let trustProvider: BackendTrustProvider
    public let queue: DispatchQueue
    public let callbackQueue: DispatchQueue
    public let group: ZMSDispatchGroup

    public weak var delegate: NetworkSocketDelegate?

    public func open() {
        preconditionQueue()

        state = .connecting

        let hostName = url.host!
        let port = url.port ?? 443

        var inStream: InputStream?
        var outStream: OutputStream?
        Stream.getStreamsToHost(withName: hostName, port: port, inputStream: &inStream, outputStream: &outStream)
        inputStream = inStream
        outputStream = outStream

        guard let inputStream, let outputStream else {
            fatal("Missing streams")
        }

        inputStream.delegate = self
        outputStream.delegate = self

        CFReadStreamSetDispatchQueue(inputStream, queue)
        CFWriteStreamSetDispatchQueue(outputStream, queue)

        let sslSettings: [AnyHashable: Any] = [
            kCFStreamSSLPeerName: hostName,
            kCFStreamSSLValidatesCertificateChain: false,
        ]

        inputStream.setProperty(sslSettings, forKey: Stream.PropertyKey(kCFStreamPropertySSLSettings as String))

        inputStream.setProperty(
            StreamSocketSecurityLevel.tlSv1,
            forKey: Stream.PropertyKey.socketSecurityLevelKey
        )

        inputStream.setProperty(
            StreamNetworkServiceTypeValue.background,
            forKey: Stream.PropertyKey.networkServiceType
        )

        inputStream.open()
        outputStream.open()
    }

    public func close() {
        close(syncDelegate: false)
    }

    @objc(writeData:)
    public func write(data dataToWrite: Data) {
        dataToWrite.withUnsafeBytes { (unsafeBufferPointer: UnsafeRawBufferPointer) in
            self.write(dispatchData: DispatchData(bytes: unsafeBufferPointer))
        }
    }

    // MARK: Fileprivate

    fileprivate enum State {
        case readyToConnect
        case connecting
        case connected
        case stopped
    }

    fileprivate var state: State = .readyToConnect

    fileprivate var didCheckTrust = false
    fileprivate var trusted = false

    fileprivate var inputStream: InputStream?
    fileprivate var outputStream: OutputStream?

    fileprivate let dataBuffer = DataBuffer()

    fileprivate func withDelegate(_ perform: @escaping (NetworkSocketDelegate) -> Void, sync: Bool = false) {
        guard let delegate else {
            return
        }

        if sync {
            perform(delegate)
        } else {
            group.async(on: callbackQueue) {
                perform(delegate)
            }
        }
    }

    fileprivate func write(dispatchData: DispatchData) {
        preconditionQueue()

        guard state != .stopped else {
            return
        }

        guard let outputStream, outputStream.streamStatus != .error else {
            close()
            return
        }

        dataBuffer.append(data: dispatchData)

        writeDataIfPossible()
    }

    @inline(__always)
    fileprivate func preconditionQueue() {
        dispatchPrecondition(condition: .onQueue(queue))
    }

    fileprivate func isOnQueue() -> Bool {
        DispatchQueue.getSpecific(key: queueMarkerKey) != nil
    }

    fileprivate func checkTrust(for stream: Stream) -> Bool {
        if didCheckTrust {
            return trusted
        }
        didCheckTrust = true

        guard let peerTrustValue = stream.property(forKey: kCFStreamPropertySSLPeerTrust as Stream.PropertyKey) else {
            trusted = false
            return false
        }

        let peerTrust = peerTrustValue as! SecTrust

        trusted = trustProvider.verifyServerTrust(trust: peerTrust, host: url.host)
        if !trusted {
            close()
        }
        return trusted
    }

    fileprivate func onBytesAvailable() {
        // Check the general state
        guard state != .stopped else {
            return
        }

        // Check if we have the output stream
        guard let inputStream else {
            fatal("Input stream is missing")
        }

        let inputBufferCount = 4 * 1024
        var inputBuffer = Data(count: inputBufferCount)

        let bytesRead = inputBuffer.withUnsafeMutableBytes { (pointer: UnsafeMutableRawBufferPointer) -> Int in
            guard let bytes = pointer.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return 0 }
            return inputStream.read(bytes, maxLength: inputBufferCount)
        }

        guard bytesRead > 0 else {
            return
        }

        inputBuffer.removeLast(inputBufferCount - bytesRead)
        withDelegate({ delegate in
            delegate.didReceive(data: inputBuffer, on: self)
        }, sync: false)
    }

    fileprivate func onHasSpaceAvailable() {
        // Check the general state
        guard state != .stopped else {
            return
        }

        // Check if we have the output stream
        guard let outputStream else {
            fatal("Output stream is missing")
        }

        // Check if we are already writing to the stream
        assert(
            outputStream.streamStatus != .writing,
            "Error: Trying to write into output stream, but stream is already writing. Threading issue?"
        )

        // Check if the stream is errored
        guard outputStream.streamStatus != .error else {
            close()
            return
        }

        // Check if there is a data to write
        guard !dataBuffer.data.isEmpty else {
            return
        }

        writeDataIfPossible()
    }

    fileprivate func writeDataIfPossible() {
        // Check if we have the output stream
        guard let outputStream else {
            fatal("Output stream is missing")
        }

        guard outputStream.hasSpaceAvailable else {
            return
        }

        let data = dataBuffer.data

        let bytesWritten = data.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) -> Int in
            outputStream.write(bytes, maxLength: data.count)
        }

        if bytesWritten > 0 {
            dataBuffer.clear(until: bytesWritten)
        }
    }

    // MARK: Private

    private let queueMarkerKey = DispatchSpecificKey<Void>()

    private func close(syncDelegate: Bool) {
        preconditionQueue()

        guard state != .stopped else {
            return
        }

        state = .stopped

        inputStream?.delegate = nil
        inputStream?.close()

        outputStream?.delegate = nil
        outputStream?.close()

        withDelegate({ delegate in
            delegate.didClose(socket: self)
        }, sync: syncDelegate)

        delegate = nil
    }
}

// MARK: StreamDelegate

extension NetworkSocket: StreamDelegate {
    public func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        preconditionQueue()

        switch (state, eventCode) {
        case (.connecting, .openCompleted):
            if aStream == outputStream {
                state = .connected
                withDelegate({ delegate in
                    delegate.didOpen(socket: self)
                }, sync: false)
            }

        case (.connected, .hasBytesAvailable):
            guard aStream == inputStream, checkTrust(for: aStream) else {
                return
            }
            onBytesAvailable()

        case (.connected, .hasSpaceAvailable):
            guard aStream == outputStream, checkTrust(for: aStream) else {
                return
            }
            onHasSpaceAvailable()

        case (_, .errorOccurred):
            fallthrough

        case (_, .endEncountered):
            close()

        default:
            return
        }
    }
}
