//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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

// DO NOT EDIT.
// swift-format-ignore-file
//
// Generated by the Swift generator plugin for the protocol buffer compiler.
// Source: mls.proto
//
// For information on using the generated types, please see the documentation:
//   https://github.com/apple/swift-protobuf/

//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

import Foundation
import SwiftProtobuf

// If the compiler emits an error on this type, it is because this file
// was generated by a version of the `protoc` Swift plug-in that is
// incompatible with the version of SwiftProtobuf to which you are linking.
// Please ensure that you are building against the same version of the API
// that was used to generate this file.
// swiftlint:disable all
private struct _GeneratedWithProtocGenSwiftVersion: SwiftProtobuf.ProtobufAPIVersionCheck {
  struct _2: SwiftProtobuf.ProtobufAPIVersion_2 {}
  typealias Version = _2
}

public enum Mls_GroupInfoType: SwiftProtobuf.Enum {
  public typealias RawValue = Int
  case publicGroupState // = 1
  case groupInfo // = 2
  case groupInfoJwe // = 3

  public init() {
    self = .publicGroupState
  }

  public init?(rawValue: Int) {
    switch rawValue {
    case 1: self = .publicGroupState
    case 2: self = .groupInfo
    case 3: self = .groupInfoJwe
    default: return nil
    }
  }

  public var rawValue: Int {
    switch self {
    case .publicGroupState: return 1
    case .groupInfo: return 2
    case .groupInfoJwe: return 3
    }
  }

}

#if swift(>=4.2)

extension Mls_GroupInfoType: CaseIterable {
  // Support synthesized by the compiler.
}

#endif  // swift(>=4.2)

public enum Mls_RatchetTreeType: SwiftProtobuf.Enum {
  public typealias RawValue = Int
  case full // = 1
  case delta // = 2
  case reference // = 3

  public init() {
    self = .full
  }

  public init?(rawValue: Int) {
    switch rawValue {
    case 1: self = .full
    case 2: self = .delta
    case 3: self = .reference
    default: return nil
    }
  }

  public var rawValue: Int {
    switch self {
    case .full: return 1
    case .delta: return 2
    case .reference: return 3
    }
  }

}

#if swift(>=4.2)

extension Mls_RatchetTreeType: CaseIterable {
  // Support synthesized by the compiler.
}

#endif  // swift(>=4.2)

public struct Mls_GroupInfoBundle {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  public var groupInfoType: Mls_GroupInfoType {
    get {return _groupInfoType ?? .publicGroupState}
    set {_groupInfoType = newValue}
  }
  /// Returns true if `groupInfoType` has been explicitly set.
  public var hasGroupInfoType: Bool {return self._groupInfoType != nil}
  /// Clears the value of `groupInfoType`. Subsequent reads from it will return its default value.
  public mutating func clearGroupInfoType() {self._groupInfoType = nil}

  public var ratchetTreeType: Mls_RatchetTreeType {
    get {return _ratchetTreeType ?? .full}
    set {_ratchetTreeType = newValue}
  }
  /// Returns true if `ratchetTreeType` has been explicitly set.
  public var hasRatchetTreeType: Bool {return self._ratchetTreeType != nil}
  /// Clears the value of `ratchetTreeType`. Subsequent reads from it will return its default value.
  public mutating func clearRatchetTreeType() {self._ratchetTreeType = nil}

  public var groupInfo: Data {
    get {return _groupInfo ?? Data()}
    set {_groupInfo = newValue}
  }
  /// Returns true if `groupInfo` has been explicitly set.
  public var hasGroupInfo: Bool {return self._groupInfo != nil}
  /// Clears the value of `groupInfo`. Subsequent reads from it will return its default value.
  public mutating func clearGroupInfo() {self._groupInfo = nil}

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public init() {}

  fileprivate var _groupInfoType: Mls_GroupInfoType?
  fileprivate var _ratchetTreeType: Mls_RatchetTreeType?
  fileprivate var _groupInfo: Data?
}

public struct Mls_CommitBundle {
  // SwiftProtobuf.Message conformance is added in an extension below. See the
  // `Message` and `Message+*Additions` files in the SwiftProtobuf library for
  // methods supported on all messages.

  /// MlsMessage containing an MlsPlaintext Commit
  public var commit: Data {
    get {return _commit ?? Data()}
    set {_commit = newValue}
  }
  /// Returns true if `commit` has been explicitly set.
  public var hasCommit: Bool {return self._commit != nil}
  /// Clears the value of `commit`. Subsequent reads from it will return its default value.
  public mutating func clearCommit() {self._commit = nil}

  /// MlsMessage containing a Welcome
  public var welcome: Data {
    get {return _welcome ?? Data()}
    set {_welcome = newValue}
  }
  /// Returns true if `welcome` has been explicitly set.
  public var hasWelcome: Bool {return self._welcome != nil}
  /// Clears the value of `welcome`. Subsequent reads from it will return its default value.
  public mutating func clearWelcome() {self._welcome = nil}

  public var groupInfoBundle: Mls_GroupInfoBundle {
    get {return _groupInfoBundle ?? Mls_GroupInfoBundle()}
    set {_groupInfoBundle = newValue}
  }
  /// Returns true if `groupInfoBundle` has been explicitly set.
  public var hasGroupInfoBundle: Bool {return self._groupInfoBundle != nil}
  /// Clears the value of `groupInfoBundle`. Subsequent reads from it will return its default value.
  public mutating func clearGroupInfoBundle() {self._groupInfoBundle = nil}

  public var unknownFields = SwiftProtobuf.UnknownStorage()

  public init() {}

  fileprivate var _commit: Data?
  fileprivate var _welcome: Data?
  fileprivate var _groupInfoBundle: Mls_GroupInfoBundle?
}

#if swift(>=5.5) && canImport(_Concurrency)
extension Mls_GroupInfoType: @unchecked Sendable {}
extension Mls_RatchetTreeType: @unchecked Sendable {}
extension Mls_GroupInfoBundle: @unchecked Sendable {}
extension Mls_CommitBundle: @unchecked Sendable {}
#endif  // swift(>=5.5) && canImport(_Concurrency)

// MARK: - Code below here is support for the SwiftProtobuf runtime.

private let _protobuf_package = "mls"

extension Mls_GroupInfoType: SwiftProtobuf._ProtoNameProviding {
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "PUBLIC_GROUP_STATE"),
    2: .same(proto: "GROUP_INFO"),
    3: .same(proto: "GROUP_INFO_JWE")
  ]
}

extension Mls_RatchetTreeType: SwiftProtobuf._ProtoNameProviding {
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "FULL"),
    2: .same(proto: "DELTA"),
    3: .same(proto: "REFERENCE")
  ]
}

extension Mls_GroupInfoBundle: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".GroupInfoBundle"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .standard(proto: "group_info_type"),
    2: .standard(proto: "ratchet_tree_type"),
    3: .standard(proto: "group_info")
  ]

  public var isInitialized: Bool {
    if self._groupInfoType == nil {return false}
    if self._ratchetTreeType == nil {return false}
    if self._groupInfo == nil {return false}
    return true
  }

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularEnumField(value: &self._groupInfoType) }()
      case 2: try { try decoder.decodeSingularEnumField(value: &self._ratchetTreeType) }()
      case 3: try { try decoder.decodeSingularBytesField(value: &self._groupInfo) }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    // The use of inline closures is to circumvent an issue where the compiler
    // allocates stack space for every if/case branch local when no optimizations
    // are enabled. https://github.com/apple/swift-protobuf/issues/1034 and
    // https://github.com/apple/swift-protobuf/issues/1182
    try { if let v = self._groupInfoType {
      try visitor.visitSingularEnumField(value: v, fieldNumber: 1)
    } }()
    try { if let v = self._ratchetTreeType {
      try visitor.visitSingularEnumField(value: v, fieldNumber: 2)
    } }()
    try { if let v = self._groupInfo {
      try visitor.visitSingularBytesField(value: v, fieldNumber: 3)
    } }()
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Mls_GroupInfoBundle, rhs: Mls_GroupInfoBundle) -> Bool {
    if lhs._groupInfoType != rhs._groupInfoType {return false}
    if lhs._ratchetTreeType != rhs._ratchetTreeType {return false}
    if lhs._groupInfo != rhs._groupInfo {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}

extension Mls_CommitBundle: SwiftProtobuf.Message, SwiftProtobuf._MessageImplementationBase, SwiftProtobuf._ProtoNameProviding {
  public static let protoMessageName: String = _protobuf_package + ".CommitBundle"
  public static let _protobuf_nameMap: SwiftProtobuf._NameMap = [
    1: .same(proto: "commit"),
    2: .same(proto: "welcome"),
    3: .standard(proto: "group_info_bundle")
  ]

  public var isInitialized: Bool {
    if self._commit == nil {return false}
    if self._groupInfoBundle == nil {return false}
    if let v = self._groupInfoBundle, !v.isInitialized {return false}
    return true
  }

  public mutating func decodeMessage<D: SwiftProtobuf.Decoder>(decoder: inout D) throws {
    while let fieldNumber = try decoder.nextFieldNumber() {
      // The use of inline closures is to circumvent an issue where the compiler
      // allocates stack space for every case branch when no optimizations are
      // enabled. https://github.com/apple/swift-protobuf/issues/1034
      switch fieldNumber {
      case 1: try { try decoder.decodeSingularBytesField(value: &self._commit) }()
      case 2: try { try decoder.decodeSingularBytesField(value: &self._welcome) }()
      case 3: try { try decoder.decodeSingularMessageField(value: &self._groupInfoBundle) }()
      default: break
      }
    }
  }

  public func traverse<V: SwiftProtobuf.Visitor>(visitor: inout V) throws {
    // The use of inline closures is to circumvent an issue where the compiler
    // allocates stack space for every if/case branch local when no optimizations
    // are enabled. https://github.com/apple/swift-protobuf/issues/1034 and
    // https://github.com/apple/swift-protobuf/issues/1182
    try { if let v = self._commit {
      try visitor.visitSingularBytesField(value: v, fieldNumber: 1)
    } }()
    try { if let v = self._welcome {
      try visitor.visitSingularBytesField(value: v, fieldNumber: 2)
    } }()
    try { if let v = self._groupInfoBundle {
      try visitor.visitSingularMessageField(value: v, fieldNumber: 3)
    } }()
    try unknownFields.traverse(visitor: &visitor)
  }

  public static func ==(lhs: Mls_CommitBundle, rhs: Mls_CommitBundle) -> Bool {
    if lhs._commit != rhs._commit {return false}
    if lhs._welcome != rhs._welcome {return false}
    if lhs._groupInfoBundle != rhs._groupInfoBundle {return false}
    if lhs.unknownFields != rhs.unknownFields {return false}
    return true
  }
}
