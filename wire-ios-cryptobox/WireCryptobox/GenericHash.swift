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

// MARK: - GenericHash

/// Encapsulates the hash value.

public struct GenericHash: Hashable {
    // MARK: Lifecycle

    init(value: Int) {
        self.value = value
    }

    // MARK: Private

    private let value: Int
}

// MARK: CustomStringConvertible

extension GenericHash: CustomStringConvertible {
    public var description: String {
        "GenericHash \(hashValue)"
    }
}

// MARK: - GenericHashBuilder

/// This class is designed to generate the hash value for the given input data.
/// Sample usage:
///
///     let builder = GenericHashBuilder()
///     builder.append(data1)
///     builder.append(data2)
///     let hash = builder.build()
public final class GenericHashBuilder {
    // MARK: Lifecycle

    init() {
        self.cryptoState = UnsafeMutableRawBufferPointer.allocate(
            byteCount: crypto_generichash_statebytes(),
            alignment: 64
        )
        self.opaqueCryptoState = OpaquePointer(cryptoState.baseAddress!)

        crypto_generichash_init(opaqueCryptoState, nil, 0, GenericHashBuilder.size)
    }

    // MARK: Public

    public func append(_ data: Data) {
        assert(state != .done, "This builder cannot be used any more: hash is already calculated")
        state = data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> State in
            crypto_generichash_update(
                opaqueCryptoState,
                bytes.baseAddress!.assumingMemoryBound(to: UInt8.self),
                UInt64(data.count)
            )
            return .readyToBuild
        }
    }

    public func build() -> GenericHash {
        assert(state != .done, "This builder cannot be used any more: hash is already calculated")
        var hashBytes: [UInt8] = Array(repeating: 0, count: GenericHashBuilder.size)
        crypto_generichash_final(opaqueCryptoState, &hashBytes, GenericHashBuilder.size)
        state = .done
        let bigEndianUInt = hashBytes.withUnsafeBytes { $0.load(as: Int.self) }
        let value = CFByteOrderGetCurrent() == CFByteOrder(CFByteOrderLittleEndian.rawValue)
            ? Int(bigEndian: bigEndianUInt)
            : bigEndianUInt

        return GenericHash(value: value)
    }

    // MARK: Private

    private enum State {
        case initial
        case readyToBuild
        case done
    }

    private static let size = MemoryLayout<Int>.size

    private var cryptoState: UnsafeMutableRawBufferPointer
    private var opaqueCryptoState: OpaquePointer

    private var state: State = .initial
}
