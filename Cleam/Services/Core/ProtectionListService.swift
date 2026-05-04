import Foundation

actor ProtectionListService {
    private static let systemCriticalBundles: Set<String> = [
        "com.apple.finder",
        "com.apple.dock",
        "com.apple.loginwindow",
        "com.apple.SystemPreferences",
        "com.apple.systempreferences",
        "com.apple.Safari",
        "com.apple.Terminal",
        "com.apple.dt.Xcode",
        "com.apple.AppStore",
        "com.apple.mail",
        "com.apple.iChat",
        "com.apple.AddressBook",
        "com.apple.iCal",
        "com.apple.Preview",
        "com.apple.TextEdit",
        "com.apple.ActivityMonitor",
        "com.apple.DiskUtility",
        "com.apple.KeychainAccess",
        "com.apple.ScriptEditor2",
        "com.apple.Automator",
        "com.apple.systemuiserver",
        "com.apple.Spotlight",
        "com.apple.notificationcenterui",
        "com.apple.controlcenter",
        "com.apple.WiFiAgent",
        "com.apple.AirPlayUIAgent",
        "com.apple.coreservices.uiagent",
        "com.apple.SecurityAgent",
    ]

    private static let dataProtectedBundles: Set<String> = [
        "com.1password.1password",
        "com.agilebits.onepassword7",
        "com.bitwarden.desktop",
        "com.lastpass.LastPass",
        "com.keepassxc.keepassxc",
        "com.microsoft.VSCode",
        "com.jetbrains.intellij",
        "com.jetbrains.CLion",
        "com.jetbrains.WebStorm",
        "com.jetbrains.pycharm",
        "com.jetbrains.goland",
        "com.sublimetext.4",
        "com.googlecode.iterm2",
        "com.microsoft.Outlook",
        "com.microsoft.Word",
        "com.microsoft.Excel",
        "com.microsoft.Powerpoint",
        "com.tinyspeck.slackmacgap",
        "com.hnc.Discord",
        "com.telegram.desktop",
        "us.zoom.xos",
        "com.skype.skype",
        "com.readdle.smartemail-macos",
        "com.sequelpro.SequelPro",
        "com.tinyapp.TablePlus",
        "com.docker.docker",
        "com.parallels.desktop.console",
        "com.vmware.fusion",
    ]

    private static let protectedPaths: Set<String> = [
        "/Applications/Safari.app",
        "/Applications/App Store.app",
        "/Applications/System Preferences.app",
        "/Applications/System Settings.app",
        "/System/Applications",
    ]

    func isProtected(path: String) -> Bool {
        if Self.protectedPaths.contains(path) { return true }

        if let bundleID = extractBundleID(from: path) {
            if Self.systemCriticalBundles.contains(bundleID) { return true }
        }

        return false
    }

    func isDataProtected(bundleID: String) -> Bool {
        Self.dataProtectedBundles.contains(bundleID)
    }

    func isSystemCritical(bundleID: String) -> Bool {
        Self.systemCriticalBundles.contains(bundleID)
    }

    private func extractBundleID(from path: String) -> String? {
        guard path.hasSuffix(".app") else { return nil }
        let url = URL(fileURLWithPath: path)
        return Bundle(url: url)?.bundleIdentifier
    }
}
