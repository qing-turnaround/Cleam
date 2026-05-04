import Foundation

actor DiskMetricsService {
    private let fileManager = FileManager.default

    func collect() -> [DiskStatus] {
        var disks: [DiskStatus] = []

        guard let mountedVolumes = fileManager.mountedVolumeURLs(
            includingResourceValuesForKeys: [.volumeNameKey, .volumeTotalCapacityKey, .volumeAvailableCapacityKey, .volumeIsInternalKey],
            options: [.skipHiddenVolumes]
        ) else { return [] }

        for volume in mountedVolumes {
            guard let values = try? volume.resourceValues(forKeys: [
                .volumeNameKey,
                .volumeTotalCapacityKey,
                .volumeAvailableCapacityKey,
                .volumeIsInternalKey,
            ]) else { continue }

            let name = values.volumeName ?? volume.lastPathComponent
            let total = UInt64(values.volumeTotalCapacity ?? 0)
            let available = UInt64(values.volumeAvailableCapacity ?? 0)
            let isInternal = values.volumeIsInternal ?? true

            guard total > 0 else { continue }

            disks.append(DiskStatus(
                id: volume.path,
                name: name,
                mountPoint: volume.path,
                totalBytes: total,
                usedBytes: total - available,
                isInternal: isInternal
            ))
        }

        return disks
    }
}
