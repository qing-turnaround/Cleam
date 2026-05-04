import Foundation

enum ServiceFactory {
    static let logger = OperationLogger()
    static let whitelist = WhitelistService()
    static let protectionList = ProtectionListService()
    static let shell = ShellCommandService()

    static var pathValidation: PathValidationService {
        PathValidationService(protectionList: protectionList, whitelist: whitelist)
    }

    static var fileOps: FileOperationService {
        FileOperationService(pathValidation: pathValidation, logger: logger)
    }
}
