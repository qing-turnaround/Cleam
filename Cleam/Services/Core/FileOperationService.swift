import Foundation

enum FileOperationMode {
    case trash
    case permanent
}

enum FileOperationError: LocalizedError {
    case validationFailed(PathValidationError)
    case deletionFailed(String)
    case dryRun
    case fileNotFound

    var errorDescription: String? {
        switch self {
        case .validationFailed(let error): return "Validation: \(error.localizedDescription)"
        case .deletionFailed(let msg): return "Deletion failed: \(msg)"
        case .dryRun: return "Dry run mode - no files deleted"
        case .fileNotFound: return "File not found"
        }
    }
}

actor FileOperationService {
    private let pathValidation: PathValidationService
    private let logger: OperationLogger
    private let fileManager = FileManager.default

    init(pathValidation: PathValidationService, logger: OperationLogger) {
        self.pathValidation = pathValidation
        self.logger = logger
    }

    func delete(
        url: URL,
        mode: FileOperationMode = .trash,
        isDryRun: Bool = false
    ) async throws -> UInt64 {
        do {
            try await pathValidation.validate(url)
        } catch let error as PathValidationError {
            throw FileOperationError.validationFailed(error)
        }

        guard fileManager.fileExists(atPath: url.path) else {
            throw FileOperationError.fileNotFound
        }

        let size = url.isDirectory
            ? fileManager.directorySize(at: url)
            : fileManager.fileSize(at: url)

        if isDryRun {
            await logger.log(operation: "dry-run", path: url.path, sizeBytes: size, status: "skipped")
            return size
        }

        do {
            switch mode {
            case .trash:
                try fileManager.trashItem(at: url, resultingItemURL: nil)
            case .permanent:
                try fileManager.removeItem(at: url)
            }
            await logger.log(operation: "delete", path: url.path, sizeBytes: size, status: "success")
            return size
        } catch {
            await logger.log(operation: "delete", path: url.path, sizeBytes: size, status: "failed: \(error.localizedDescription)")
            throw FileOperationError.deletionFailed(error.localizedDescription)
        }
    }

    func deleteBatch(
        urls: [URL],
        mode: FileOperationMode = .trash,
        isDryRun: Bool = false,
        progress: @escaping (Int, Int) -> Void
    ) async -> (freedBytes: UInt64, deletedCount: Int, errors: [OperationError]) {
        var freedBytes: UInt64 = 0
        var deletedCount = 0
        var errors: [OperationError] = []

        for (index, url) in urls.enumerated() {
            do {
                let size = try await delete(url: url, mode: mode, isDryRun: isDryRun)
                freedBytes += size
                deletedCount += 1
            } catch {
                errors.append(OperationError(path: url, message: error.localizedDescription))
            }
            progress(index + 1, urls.count)
        }

        return (freedBytes, deletedCount, errors)
    }
}
