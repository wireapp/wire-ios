//
//  NSURLSessionConfiguration+Debugging.swift
//  ZMTransport
//
//  Created by Marco Conti on 23/03/2017.
//  Copyright © 2017 Wire. All rights reserved.
//

import Foundation

extension URLSessionConfiguration {
    
    public var configurationDump: String {
        var dump = [
            "identifier: \(self.identifier ?? "nil")",
            "allowsCellularAccess: \(self.allowsCellularAccess)",
            "httpMaximumConnectionsPerHost: \(self.httpMaximumConnectionsPerHost)",
            "httpShouldUsePipelining: \(self.httpShouldUsePipelining)",
            "httpShouldSetCookies: \(self.httpShouldSetCookies)",
            "isDiscretionary: \(self.isDiscretionary)",
            "sessionSendsLaunchEvents: \(self.sessionSendsLaunchEvents)",
            "timeoutIntervalForRequest: \(self.timeoutIntervalForRequest)",
            "timeoutIntervalForResource: \(self.timeoutIntervalForResource)",
            "tlsMaximumSupportedProtocol: \(self.tlsMaximumSupportedProtocol)",
            "tlsMinimumSupportedProtocol: \(self.tlsMinimumSupportedProtocol)",
        ]
        if #available(iOSApplicationExtension 9.0, *) {
            dump.append("shouldUseExtendedBackgroundIdleMode: \(self.shouldUseExtendedBackgroundIdleMode)")
        }
        return dump.joined(separator: "\n\t")
    }
}
