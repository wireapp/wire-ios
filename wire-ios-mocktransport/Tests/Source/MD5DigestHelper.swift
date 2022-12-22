//
//  MD5DigestHelper.swift
//  WireMockTransportTests
//
//  Created by Agisilaos Tsaraboulidis on 18.07.22.
//  Copyright © 2022 Zeta Project. All rights reserved.
//

import Foundation

@objcMembers
 public class MD5DigestHelper: NSObject {

     static func md5Digest(for data: Data) -> Data {
         return data.zmMD5Digest()
     }

 }
