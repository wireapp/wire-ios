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


#import "ZMServerTrust.h"
@import WireSystem;
#import <mach-o/dyld.h>

// To dump certificate data, use
//     CFIndex const certCount = SecTrustGetCertificateCount(serverTrust);
// and
//     SecCertificateRef cert0 = SecTrustGetCertificateAtIndex(serverTrust, 0);
//     SecCertificateRef cert1 = SecTrustGetCertificateAtIndex(serverTrust, 1);
// etc. and then
//     SecCertificateCopyData(cert1)
// to dump the certificate data.
//
//
// Also
//     CFBridgingRelease(SecCertificateCopyValues(cert1, @[kSecOIDX509V1SubjectName], NULL))

/// Returns the public key of the leaf certificate associated with the trust object
static SecKeyRef publicKeyAssociatedWithServerTrust(SecTrustRef const serverTrust)
{
    SecKeyRef key = nil;
    __block SecPolicyRef policy = SecPolicyCreateBasicX509();
    
    __block SecCertificateRef certificate = SecTrustGetCertificateAtIndex(serverTrust, 0); // leaf certificate
    
    SecCertificateRef certificatesCArray[] = { certificate};
    CFArrayRef certificates = CFArrayCreate(NULL, (const void **)certificatesCArray, 1, NULL);
    __block SecTrustRef trust = NULL;
    
    void(^finally)(void) = ^{
        if (certificates) {
            CFRelease(certificates);
        }
        
        if (trust) {
            CFRelease(trust);
        }
        
        CFRelease(policy);
    };
    
    if (SecTrustCreateWithCertificates(certificates, policy, &trust) != noErr) {
        finally();
        return nil;
    }
    
    SecTrustResultType result;
    if (SecTrustEvaluate(trust, &result) != noErr) {
        finally();
        return nil;
    }
    
    key = SecTrustCopyPublicKey(trust);
        
    finally();
    
    return key;
}

BOOL verifyServerTrustWithPinnedKeys(SecTrustRef const serverTrust, NSArray *pinnedKeys)
{    
    SecTrustResultType result;
    if (SecTrustEvaluate(serverTrust, &result) != noErr) {
        return NO;
    }
    
    if (result != kSecTrustResultProceed && result != kSecTrustResultUnspecified) {
        return NO;
    }
    
    if (pinnedKeys.count == 0) {
        return YES;
    }
    
    SecKeyRef publicKey = publicKeyAssociatedWithServerTrust(serverTrust);
    
    if (publicKey == nil) {
        return NO;
    }
    
    for (id pinnedKey in pinnedKeys) {
        if ([(__bridge id)publicKey isEqual:pinnedKey]) {
            CFRelease(publicKey);
            return YES;
        }
    }
    
    CFRelease(publicKey);
    return NO;
}
