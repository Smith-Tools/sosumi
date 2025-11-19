import Foundation

public struct HIGPage: Codable {
    public let metadata: HIGMetadata?
    public let kind: String?
    public let identifier: HIGIdentifier?
    public let hierarchy: HIGHierarchy?
    public let sections: [HIGContentNode]?
    public let primaryContentSections: [HIGPrimaryContentSection]?
    public let abstract: [HIGContentNode]?
    public let topicSections: [HIGTopicSection]?
    public let topicSectionsStyle: String?
    public let references: [String: HIGReferenceValue]?
    public let legalNotices: HIGLegalNotices?
    public let schemaVersion: HIGVersionInfo?
}

public struct HIGMetadata: Codable {
    public let role: String?
    public let title: String?
    public let images: [HIGImage]?
    public let availableLocales: [String]?
    public let customMetadata: [String: String]?
}

public struct HIGImage: Codable {
    public let identifier: String?
    public let type: String?
}

public struct HIGIdentifier: Codable {
    public let interfaceLanguage: String?
    public let url: String?
}

public struct HIGHierarchy: Codable {
    public let paths: [[String]]?
}

public struct HIGPrimaryContentSection: Codable {
    public let kind: String?
    public let content: [HIGContentNode]?
}

public struct HIGTopicSection: Codable {
    public let title: String?
    public let identifiers: [String]?
    public let anchor: String?
}

public struct HIGReferenceValue: Codable {
    public let type: String?
    public let title: String?
    public let url: String?
    public let identifier: String?
    public let abstract: [HIGContentNode]?
    public let role: String?
    public let kind: String?
    public let images: [HIGImage]?
    public let alt: String?
    public let variants: [HIGImageVariant]?

    public var isImageReference: Bool {
        variants != nil
    }
}

public struct HIGImageVariant: Codable {
    public let traits: [String]?
    public let url: String?
}

public struct HIGLegalNotices: Codable {
    public let copyright: String?
    public let termsOfUse: String?
    public let privacy: String?
    public let privacyPolicy: String?
}

public struct HIGVersionInfo: Codable {
    public let major: Int?
    public let minor: Int?
    public let patch: Int?
}

public struct HIGTableOfContents: Codable {
    public let includedArchiveIdentifiers: [String]?
    public let interfaceLanguages: HIGInterfaceLanguages?
    public let references: [String: HIGIconReference]?
    public let schemaVersion: HIGVersionInfo?
}

public struct HIGInterfaceLanguages: Codable {
    public let swift: [HIGTocItem]?
}

public struct HIGTocItem: Codable {
    public let children: [HIGTocItem]?
    public let icon: String?
    public let path: String?
    public let title: String?
    public let type: String?
}

public struct HIGIconReference: Codable {
    public let alt: String?
    public let identifier: String?
    public let type: String?
    public let variants: [HIGImageVariant]?
}

public struct HIGContentNode: Codable {
    public let type: String?
    public let text: String?
    public let title: String?
    public let name: String?
    public let code: String?
    public let identifier: String?
    public let url: String?
    public let level: Int?
    public let style: String?
    public let anchor: String?
    public let isActive: Bool?
    public let inlineContent: [HIGContentNode]?
    public let content: [HIGContentNode]?
    public let items: [String]?
    public let columns: [HIGColumn]?
    public let numberOfColumns: Int?
    public let tabs: [HIGTab]?
    public let rows: [[[HIGContentNode]]]?
    public let header: String?
    public let metadata: HIGContentMetadata?
}

public struct HIGColumn: Codable {
    public let size: Int?
    public let content: [HIGContentNode]?
}

public struct HIGTab: Codable {
    public let title: String?
    public let content: [HIGContentNode]?
}

public struct HIGContentMetadata: Codable {
    public let deviceFrame: String?
    public let abstract: [HIGContentNode]?
}
