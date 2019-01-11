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

@import Security;
CF_ASSUME_NONNULL_BEGIN
CF_IMPLICIT_BRIDGING_ENABLED

extern BOOL verifyServerTrustWithPinnedKeys(SecTrustRef const serverTrust, NSArray * pinnedKeys);

// A wrapper to use SecCertificateCopyPublicKey from Swift because it is marked as introduced in 10.3 and forces to bump deployment target to iOS 10.3
// We have started using this method because we needed to be compatible with iOS8 (see https://github.com/wireapp/wire-ios-transport/pull/33)
// It is probably incorrectly marked in Foundation API headers, because it is clearly available in earlier iOS versions (we had this in production for a long time).
extern __nullable SecKeyRef _SecCertificateCopyPublicKey(SecCertificateRef certificate);

CF_ASSUME_NONNULL_END
CF_IMPLICIT_BRIDGING_DISABLED
