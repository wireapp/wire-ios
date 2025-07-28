//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

package import AWSS3
package import Foundation

// sourcery: AutoMockable
package protocol S3ClientProtocol: Sendable {

    func getObject(input: GetObjectInput) async throws -> GetObjectOutput
    func putObject(input: PutObjectInput) async throws -> PutObjectOutput
    func uploadPart(input: UploadPartInput) async throws -> UploadPartOutput
    func createMultipartUpload(input: CreateMultipartUploadInput) async throws -> CreateMultipartUploadOutput
    func completeMultipartUpload(input: CompleteMultipartUploadInput) async throws -> CompleteMultipartUploadOutput
    func presignedURLForGetObject(input: GetObjectInput, expiration: Foundation.TimeInterval) async throws -> URL

}

extension S3Client: S3ClientProtocol, @unchecked @retroactive Sendable {}
