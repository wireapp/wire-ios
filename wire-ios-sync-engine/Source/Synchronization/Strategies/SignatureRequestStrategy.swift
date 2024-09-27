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

// Sign a PDF document
public final class SignatureRequestStrategy: AbstractRequestStrategy, ZMSingleRequestTranscoder {
    // MARK: - Private Property

    private let syncContext: NSManagedObjectContext
    private var signatureResponse: SignatureResponse?
    private var retrieveResponse: SignatureRetrieveResponse?

    // MARK: - Public Property

    var requestSync: ZMSingleRequestSync?
    var retrieveSync: ZMSingleRequestSync?

    // MARK: - AbstractRequestStrategy

    @objc
    override public init(
        withManagedObjectContext managedObjectContext: NSManagedObjectContext,
        applicationStatus: ApplicationStatus
    ) {
        self.syncContext = managedObjectContext
        super.init(
            withManagedObjectContext: managedObjectContext,
            applicationStatus: applicationStatus
        )
        self.requestSync = ZMSingleRequestSync(
            singleRequestTranscoder: self,
            groupQueue: syncContext
        )
        self.retrieveSync = ZMSingleRequestSync(
            singleRequestTranscoder: self,
            groupQueue: syncContext
        )
    }

    @objc
    override public func nextRequestIfAllowed(for apiVersion: APIVersion) -> ZMTransportRequest? {
        guard let signatureStatus = syncContext.signatureStatus else {
            return nil
        }

        switch signatureStatus.state {
        case .initial:
            break

        case .waitingForConsentURL:
            guard let requestSync else {
                return nil
            }
            requestSync.readyForNextRequestIfNotBusy()
            return requestSync.nextRequest(for: apiVersion)

        case .waitingForCodeVerification:
            break

        case .waitingForSignature:
            guard let retrieveSync else {
                return nil
            }
            retrieveSync.readyForNextRequestIfNotBusy()
            return retrieveSync.nextRequest(for: apiVersion)

        case .signatureInvalid:
            break

        case .finished:
            break
        }
        return nil
    }

    // MARK: - ZMSingleRequestTranscoder

    public func request(for sync: ZMSingleRequestSync, apiVersion: APIVersion) -> ZMTransportRequest? {
        switch sync {
        case requestSync:
            makeSignatureRequest(apiVersion: apiVersion)
        case retrieveSync:
            makeRetrieveSignatureRequest(apiVersion: apiVersion)
        default:
            nil
        }
    }

    public func didReceive(
        _ response: ZMTransportResponse,
        forSingleRequest sync: ZMSingleRequestSync
    ) {
        guard let signatureStatus = syncContext.signatureStatus else {
            return
        }

        switch response.result {
        case .success:
            switch sync {
            case requestSync:
                processRequestSignatureSuccess(with: response.rawData)
            case retrieveSync:
                processRetrieveSignatureSuccess(with: response.rawData)
            default:
                break
            }

        case .temporaryError,
             .tryAgainLater,
             .expired:
            break

        case .permanentError:
            switch sync {
            case requestSync:
                signatureStatus.didReceiveError(.noConsentURL)
            case retrieveSync:
                signatureStatus.didReceiveError(.retrieveFailed)
            default:
                break
            }

        default:
            switch sync {
            case requestSync:
                signatureStatus.didReceiveError(.noConsentURL)
            case retrieveSync:
                signatureStatus.didReceiveError(.retrieveFailed)
            default:
                break
            }
        }
    }

    // MARK: - Helpers

    private func makeSignatureRequest(apiVersion: APIVersion) -> ZMTransportRequest? {
        guard
            let signatureStatus = syncContext.signatureStatus,
            let encodedHash = signatureStatus.encodedHash,
            let documentID = signatureStatus.documentID,
            let fileName = signatureStatus.fileName,
            let payload = SignaturePayload(
                documentID: documentID,
                fileName: fileName,
                hash: encodedHash
            ).jsonDictionary as NSDictionary?
        else {
            return nil
        }

        return ZMTransportRequest(
            path: "/signature/request",
            method: .post,
            payload: payload as ZMTransportData,
            apiVersion: apiVersion.rawValue
        )
    }

    private func makeRetrieveSignatureRequest(apiVersion: APIVersion) -> ZMTransportRequest? {
        guard let responseID = signatureResponse?.responseID else {
            return nil
        }

        return ZMTransportRequest(
            path: "/signature/pending/\(responseID)",
            method: .get,
            payload: nil,
            apiVersion: apiVersion.rawValue
        )
    }

    private func processRequestSignatureSuccess(with data: Data?) {
        guard
            let responseData = data,
            let signatureStatus = syncContext.signatureStatus
        else {
            return
        }

        do {
            let decodedResponse = try JSONDecoder().decode(
                SignatureResponse.self,
                from: responseData
            )
            signatureResponse = decodedResponse
            signatureStatus.didReceiveConsentURL(signatureResponse?.consentURL)
        } catch {
            Logging.network.debug("Failed to decode SignatureResponse with \(error)")
        }
    }

    private func processRetrieveSignatureSuccess(with data: Data?) {
        guard
            let responseData = data,
            let signatureStatus = syncContext.signatureStatus
        else {
            return
        }

        do {
            let decodedResponse = try JSONDecoder().decode(
                SignatureRetrieveResponse.self,
                from: responseData
            )
            retrieveResponse = decodedResponse
            signatureStatus.didReceiveSignature(with: decodedResponse.cms)
        } catch {
            Logging.network.debug("Failed to decode SignatureRetrieveResponse with \(error)")
        }
    }
}

// MARK: - SignaturePayload

private struct SignaturePayload: Codable, Equatable {
    let documentID: String?
    let fileName: String?
    let hash: String?
    var jsonDictionary: [String: String]? {
        makeJSONDictionary()
    }

    private enum CodingKeys: String, CodingKey {
        case documentID = "documentId"
        case fileName = "name"
        case hash
    }

    private func makeJSONDictionary() -> [String: String]? {
        let signaturePayload = SignaturePayload(
            documentID: documentID,
            fileName: fileName,
            hash: hash
        )
        guard
            let jsonData = try? JSONEncoder().encode(signaturePayload),
            let payload = try? JSONDecoder().decode([String: String].self, from: jsonData)
        else {
            return nil
        }
        return payload
    }
}

// MARK: - SignatureResponse

private struct SignatureResponse: Codable, Equatable {
    let responseID: String?
    let consentURL: URL?

    private enum CodingKeys: String, CodingKey {
        case consentURL
        case responseID = "responseId"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.responseID = try container.decodeIfPresent(String.self, forKey: .responseID)
        guard
            let consentURLString = try container.decodeIfPresent(String.self, forKey: .consentURL),
            let url = URL(string: consentURLString)
        else {
            self.consentURL = nil
            return
        }

        self.consentURL = url
    }
}

// MARK: - SignatureRetrieveResponse

private struct SignatureRetrieveResponse: Codable, Equatable {
    let documentId: String?
    let cms: Data?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.documentId = try container.decodeIfPresent(String.self, forKey: .documentId)
        guard
            let cmsBase64String = try container.decodeIfPresent(String.self, forKey: .cms),
            let cmsEncodedData = Data(base64Encoded: cmsBase64String)
        else {
            self.cms = nil
            return
        }
        self.cms = cmsEncodedData
    }
}
