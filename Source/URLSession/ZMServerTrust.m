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

static BOOL verifyServerTrustWithPinnedKeys(SecTrustRef const serverTrust, NSArray *pinnedKeys);

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

static SecKeyRef publicKeyFromCertificateData(NSData *certificateData)
{
    SecCertificateRef certificate = SecCertificateCreateWithData(NULL, (CFDataRef)certificateData);
    
    if (certificate == nil) {
        [NSException raise:NSInvalidArgumentException format:@"Error decoding certificate for pinned key"];
    }
    
    SecKeyRef key = SecCertificateCopyPublicKey(certificate);
    CFRelease(certificate);

    if (key == nil) {
        [NSException raise:NSInvalidArgumentException format:@"Error extracing pinned key from certificate"];
    }
    
    return key;
}

static SecKeyRef wirePublicKey()
{
    NSString *base64Cert = @" \
    MIIFDDCCA/SgAwIBAgIQC7HK4y3OxqQjbYqDk1wVrDANBgkqhkiG9w0BAQsFADBN \
    MQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMScwJQYDVQQDEx5E \
    aWdpQ2VydCBTSEEyIFNlY3VyZSBTZXJ2ZXIgQ0EwHhcNMTYxMTAzMDAwMDAwWhcN \
    MTgwMTA0MTIwMDAwWjBYMQswCQYDVQQGEwJDSDEMMAoGA1UECBMDWnVnMQwwCgYD \
    VQQHEwNadWcxGDAWBgNVBAoTD1dpcmUgU3dpc3MgR21iSDETMBEGA1UEAwwKKi53 \
    aXJlLmNvbTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAK3mMwVrr51S \
    mH4DTV93VY1J6iFbZeF6kJwnGOpv7FjNeU0ytG6PRSpzMTQD7Q8welYkb6WbChHn \
    1/KYteSXLOLmYrmfNSEldW6sbabIyeemI3pnvfQ3GuXJN+aU4WLiuo2fLxuqSYmP \
    ZkWPZxmnYneKli+7sAHqCJ8dpjjOx3qQgodjTl3fhI0OLAbH4G/pFq3FUJgc7yxz \
    1A6MpJv5vgby9nidZ4zzYjPxqHl25iFtVjN4n7nGCaA/YPleTXx3wDa1btsOGHCw \
    2ndAvOTW/FNbIBTZK4Dqs4Xf9cR6JNbjso6Hi0yBx2JK8r2wRJnZer/n9idRDNPh \
    Y/b7HiNk2K0CAwEAAaOCAdswggHXMB8GA1UdIwQYMBaAFA+AYRyCMWHVLyjnjUY4 \
    tCzhxtniMB0GA1UdDgQWBBT/SIDwnMHi0O3A0H/c3Jh8K19NnDAfBgNVHREEGDAW \
    ggoqLndpcmUuY29tggh3aXJlLmNvbTAOBgNVHQ8BAf8EBAMCBaAwHQYDVR0lBBYw \
    FAYIKwYBBQUHAwEGCCsGAQUFBwMCMGsGA1UdHwRkMGIwL6AtoCuGKWh0dHA6Ly9j \
    cmwzLmRpZ2ljZXJ0LmNvbS9zc2NhLXNoYTItZzUuY3JsMC+gLaArhilodHRwOi8v \
    Y3JsNC5kaWdpY2VydC5jb20vc3NjYS1zaGEyLWc1LmNybDBMBgNVHSAERTBDMDcG \
    CWCGSAGG/WwBATAqMCgGCCsGAQUFBwIBFhxodHRwczovL3d3dy5kaWdpY2VydC5j \
    b20vQ1BTMAgGBmeBDAECAjB8BggrBgEFBQcBAQRwMG4wJAYIKwYBBQUHMAGGGGh0 \
    dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBGBggrBgEFBQcwAoY6aHR0cDovL2NhY2Vy \
    dHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0U0hBMlNlY3VyZVNlcnZlckNBLmNydDAM \
    BgNVHRMBAf8EAjAAMA0GCSqGSIb3DQEBCwUAA4IBAQAYQUuP8OknxlnqihIOPMcy \
    Rpg25val6hmnrIfm1H66kOFpnjwv/66MhikCbJBAKlbnmuxNd1zK30CT4tbcmy1u \
    YzGxN8D5Am+pcmHg8vgmnyRt3QftHVVyu9ayoR0dGG2+00iTcY8Un0+c30ktaDE1 \
    vSKxp0VQvyhW/FHxOzFWpub11MzuJ3wf3MkdpBQL604LKY+viYKt3eXDJUZPhDOK \
    e9VCYGZLsAEGTRYMq3iIey76hbVojWYD0Hw4xHKMmM+AOiksN6WW22uxXXwRuYM+ \
    uLl9qx1HBNoeCitFfYMh+pe7UUQFs1DVNaFwAbTlOwrU1Xif8xmbvZoMm4BJUYEj";
    
    NSData *certificateData = [[NSData alloc] initWithBase64EncodedString:base64Cert options:NSDataBase64DecodingIgnoreUnknownCharacters];
    SecKeyRef key = publicKeyFromCertificateData(certificateData);
    
    assert(key != nil);
    
    return key;
}

BOOL verifyServerTrust(SecTrustRef const serverTrust, NSString *host)
{
    NSArray *pinnedKeys = @[];
    
    if (   [host hasSuffix:@"prod-nginz-https.wire.com"]
        || [host hasSuffix:@"prod-nginz-ssl.wire.com"]
        || [host hasSuffix:@"prod-assets.wire.com"]
        || [host hasSuffix:@"www.wire.com"]
        || [host isEqualToString:@"wire.com"]) {
        pinnedKeys = @[CFBridgingRelease(wirePublicKey())];
    }
    
    return verifyServerTrustWithPinnedKeys(serverTrust, pinnedKeys);
}

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

static BOOL verifyServerTrustWithPinnedKeys(SecTrustRef const serverTrust, NSArray *pinnedKeys)
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
