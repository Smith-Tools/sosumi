import Foundation

enum DocURLUtilities {
    static let baseURL = "https://developer.apple.com"
    private static let knownPrefixes = [
        "documentation/",
        "design/",
        "videos/",
        "tutorials/",
        "sample-code/"
    ]

    static func toWebURL(_ rawValue: String?) -> String? {
        guard var raw = rawValue?.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty else {
            return rawValue
        }

        guard raw.hasPrefix("doc://") else {
            return raw
        }

        raw.removeFirst("doc://".count)

        if raw.isEmpty {
            return baseURL
        }

        if raw.hasPrefix("/") {
            return baseURL + raw
        }

        let lower = raw.lowercased()
        if knownPrefixes.contains(where: { lower.hasPrefix($0) }) {
            return "\(baseURL)/\(raw)"
        }

        if let slashIndex = raw.firstIndex(of: "/") {
            let suffix = raw[slashIndex...]
            return "\(baseURL)\(suffix)"
        }

        return baseURL
    }
}
