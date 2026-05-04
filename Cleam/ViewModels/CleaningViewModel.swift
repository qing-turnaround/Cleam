import SwiftUI

@MainActor
class CleaningViewModel: ObservableObject {
    @Published var session: CleanSession = .empty
    @Published var isScanning = false
    @Published var isCleaning = false
    @Published var scanProgress: ScanProgress = .zero
    @Published var result: OperationResult?
    @Published var isDryRun = false

    private let fileOps: FileOperationService
    private let systemCleaning = SystemCleaningService()
    private let userCleaning = UserCleaningService()
    private let browserCleaning = BrowserCleaningService()
    private let developerCleaning = DeveloperCleaningService()
    private let appCacheCleaning = AppCacheCleaningService()
    private let cloudCleaning = CloudCleaningService()
    private let projectCacheCleaning = ProjectCacheCleaningService()

    init(fileOps: FileOperationService) {
        self.fileOps = fileOps
    }

    func scan() async {
        isScanning = true
        scanProgress = .zero
        session = .empty
        session.isDryRun = isDryRun
        result = nil

        var allItems: [CleanCategory: [CleanableItem]] = [:]

        let systemItems = await systemCleaning.scan()
        if !systemItems.isEmpty { allItems[.systemCaches] = systemItems }
        scanProgress.scannedItems = 1

        let userItems = await userCleaning.scan()
        if !userItems.isEmpty { allItems[.userCaches] = userItems }
        scanProgress.scannedItems = 2

        let browserItems = await browserCleaning.scan()
        if !browserItems.isEmpty { allItems[.browsers] = browserItems }
        scanProgress.scannedItems = 3

        let devItems = await developerCleaning.scan()
        if !devItems.isEmpty { allItems[.developer] = devItems }
        scanProgress.scannedItems = 4

        let appItems = await appCacheCleaning.scan()
        if !appItems.isEmpty { allItems[.applications] = appItems }
        scanProgress.scannedItems = 5

        let cloudItems = await cloudCleaning.scan()
        if !cloudItems.isEmpty { allItems[.cloud] = cloudItems }
        scanProgress.scannedItems = 6

        let projectItems = await projectCacheCleaning.scan()
        if !projectItems.isEmpty { allItems[.projectCaches] = projectItems }
        scanProgress.scannedItems = 7

        session.items = allItems
        scanProgress.totalItems = 7
        scanProgress.isComplete = true
        isScanning = false
    }

    func clean() async {
        guard !isCleaning else { return }
        isCleaning = true
        let startTime = Date()

        let selectedItems = session.items.values.flatMap { $0 }.filter(\.isSelected)
        let urls = selectedItems.map(\.path)

        let batchResult = await fileOps.deleteBatch(
            urls: urls,
            isDryRun: isDryRun
        ) { current, total in
            Task { @MainActor in
                self.scanProgress.scannedItems = current
                self.scanProgress.totalItems = total
            }
        }

        self.result = OperationResult(
            success: batchResult.errors.isEmpty,
            freedBytes: batchResult.freedBytes,
            deletedCount: batchResult.deletedCount,
            failedCount: batchResult.errors.count,
            errors: batchResult.errors,
            duration: Date().timeIntervalSince(startTime)
        )

        session.freedBytes = batchResult.freedBytes
        session.deletedCount = batchResult.deletedCount
        isCleaning = false
    }

    func toggleCategory(_ category: CleanCategory, selected: Bool) {
        guard var items = session.items[category] else { return }
        for i in items.indices {
            items[i].isSelected = selected
        }
        session.items[category] = items
    }
}
