import Foundation

/// Manages WWDC transcript bundle detection and error reporting
public struct BundleManager {

    // MARK: - Bundle Path Detection

    /// Checks for wwdc.db or wwdc_bundle.encrypted in standard locations
    public static func findBundle() -> String? {
        let fileManager = FileManager.default

        // First check for plain database in user home (v1.3.0+)
        // Plain database should only exist in ~/.sosumi/ for local development
        let userDbPath = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent(".sosumi/wwdc.db").path
        if fileManager.fileExists(atPath: userDbPath) {
            return userDbPath
        }

        // Fall back to encrypted bundle (v1.2.0+ releases)
        let encryptedBundlePaths: [String] = [
            // 1. Home directory ~/.sosumi/
            fileManager.homeDirectoryForCurrentUser.appendingPathComponent(".sosumi/wwdc_bundle.encrypted").path,
            // 2. Current directory
            fileManager.currentDirectoryPath + "/wwdc_bundle.encrypted",
            // 3. App bundle resources (if compiled in)
            Bundle.main.resourcePath?.appending("/DATA/wwdc_bundle.encrypted") ?? ""
        ].filter { !$0.isEmpty }

        for path in encryptedBundlePaths {
            if fileManager.fileExists(atPath: path) {
                return path
            }
        }

        return nil
    }

    /// Returns true if bundle is available
    public static func bundleExists() -> Bool {
        return findBundle() != nil
    }

    // MARK: - Error Reporting

    /// Prints actionable error message for missing bundle
    /// Exits with code 5 (missing dependency)
    public static func presentMissingBundleError(command: String = "sosumi") -> Never {
        let errorMessage = """
        ❌ WWDC TRANSCRIPT BUNDLE NOT FOUND

        The encrypted WWDC transcript bundle (wwdc_bundle.encrypted) is required for search functionality.
        Mock data is intentionally disabled to prevent confusion.

        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

        HOW TO FIX (Choose one option):

        OPTION 1: Download and install bundle (recommended)
        ────────────────────────────────────────────────
        1. Download bundle (850 MB):
           $ wget https://github.com/Smith-Tools/sosumi/releases/download/v1.2.0/wwdc_bundle.encrypted

        2. Install to home directory:
           $ mkdir -p ~/.sosumi
           $ mv wwdc_bundle.encrypted ~/.sosumi/

        3. Run sosumi:
           $ \(command) search "SwiftUI"

        OPTION 2: Place bundle in current directory
        ─────────────────────────────────────────
           $ wget https://github.com/Smith-Tools/sosumi/releases/download/v1.2.0/wwdc_bundle.encrypted
           $ \(command) search "SwiftUI"

        OPTION 3: Download pre-built binary (bundle included)
        ────────────────────────────────────────────────
           $ wget https://github.com/Smith-Tools/sosumi/releases/download/v1.2.0/sosumi-with-bundle
           $ chmod +x sosumi-with-bundle
           $ ./sosumi-with-bundle search "SwiftUI"

        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

        BUNDLE LOCATIONS CHECKED:
        • ./wwdc_bundle.encrypted (current directory)
        • ~/.sosumi/wwdc_bundle.encrypted (home directory)
        • Resources/DATA/wwdc_bundle.encrypted (app bundle)

        VERIFIED BUNDLE:
        • File: wwdc_bundle.encrypted
        • Size: ~850 MB
        • Type: AES-256-GCM encrypted

        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

        TROUBLESHOOTING:
        • Bundle file exists but not found? Check file name (case-sensitive)
        • File too large to download? Use OPTION 3 (pre-built binary)
        • More help? https://github.com/Smith-Tools/sosumi#installation
        """

        fputs(errorMessage + "\n", stderr)
        exit(5)  // Exit code 5: missing dependency
    }

    /// Logs bundle status for debugging
    public static func logBundleStatus() {
        if let bundlePath = findBundle() {
            let fileManager = FileManager.default
            if let attributes = try? fileManager.attributesOfItem(atPath: bundlePath),
               let size = attributes[.size] as? Int64 {
                print("📦 Bundle found: \(bundlePath)")
                print("   Size: \(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))")
            }
        } else {
            print("❌ Bundle not found")
            print("   Searched:")
            print("   - ./wwdc_bundle.encrypted")
            print("   - ~/.sosumi/wwdc_bundle.encrypted")
        }
    }
}
