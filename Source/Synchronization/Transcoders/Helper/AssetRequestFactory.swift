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


import Foundation

public class AssetRequestFactory : NSObject {
    
    let jsonContentType = "application/json"
    let octetStreamContentType = "application/octet-stream"
    
    public enum Retention : String {
        case Persistent = "persistent"
        case Eternal = "eternal"
        case Volatile = "volatile"
    }

    public func upstreamRequestForAsset(withData data: NSData, shareable: Bool = true, retention : Retention = .Persistent) -> ZMTransportRequest? {
        let path = "/assets/v3"
        guard let multipartData = try? dataForMultipartAssetUploadRequest(data, shareable: shareable, retention: retention) else { return nil }
        let request = ZMTransportRequest(path: path, method: .MethodPOST, binaryData: multipartData, type: "multipart/mixed; boundary=frontier", contentDisposition: nil)
        return request
    }
    
    func dataForMultipartAssetUploadRequest(data: NSData, shareable: Bool, retention : Retention) throws -> NSData {
        let fileDataHeader = ["Content-MD5": data.zmMD5Digest().base64String()]
        let metaData = try NSJSONSerialization.dataWithJSONObject(["public" : shareable, "retention" : retention.rawValue ], options: [])

        return .multipartDataWithItems([
            ZMMultipartBodyItem(data: metaData, contentType: jsonContentType, headers: nil),
            ZMMultipartBodyItem(data: data, contentType: octetStreamContentType, headers: fileDataHeader),
            ], boundary: "frontier")
    }
    
}
