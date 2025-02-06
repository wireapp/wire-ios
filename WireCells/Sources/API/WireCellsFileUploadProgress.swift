//
//  WireCellsFileUploadProgress.swift
//  WireCells
//
//  Created by Thomas Léger on 29/01/2025.
//

import Foundation

public enum WireCellsFileUploadProgress: Sendable {
    case started(file: WireCellsFileUploadInfo)
    case uploading(file: WireCellsFileUploadInfo, progress: Double)
    case success(file: WireCellsFileUploadInfo, uploadedFile: WireCellsUploadedFile)
    case failure(file: WireCellsFileUploadInfo, error: WireCellsFileUploadError)

    public var filePath: String {
        switch self {
        case let .started(file), let .uploading(file, _), let .success(file, _), let .failure(file, _):
            file.uploadPath
        }
    }
}
