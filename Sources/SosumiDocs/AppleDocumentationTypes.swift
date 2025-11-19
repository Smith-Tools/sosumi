import Foundation

/// Swift port of Apple documentation JSON API types from sosumi.ai TypeScript implementation
/// Based on undocumented Apple Developer JSON endpoints

// MARK: - Core Data Types

/// Represents a text fragment that can contain different content types
public struct TextFragment: Codable {
    public let type: String
    public let text: String?
    public let code: CodeValue?
    public let inlineCode: String?
    public let emphasis: [TextFragment]?
    public let strong: [TextFragment]?
    public let newlines: Int?
    public let url: String?
    public let identifier: String?
    public let heading: String?
    public let imageURL: String?
    public let aspectRatio: Double?
    public let caption: [TextFragment]?
    public let appExtension: String?
    public let enabled: Bool?
    public let technology: String?
    public let content: [TextFragment]?
    public let parameters: [Parameter]?
    public let returns: Parameter?
    public let thrown: Parameter?
    public let metadata: ContentMetadata?

    public init(
        type: String,
        text: String? = nil,
        code: CodeValue? = nil,
        inlineCode: String? = nil,
        emphasis: [TextFragment]? = nil,
        strong: [TextFragment]? = nil,
        newlines: Int? = nil,
        url: String? = nil,
        identifier: String? = nil,
        heading: String? = nil,
        imageURL: String? = nil,
        aspectRatio: Double? = nil,
        caption: [TextFragment]? = nil,
        appExtension: String? = nil,
        enabled: Bool? = nil,
        technology: String? = nil,
        content: [TextFragment]? = nil,
        parameters: [Parameter]? = nil,
        returns: Parameter? = nil,
        thrown: Parameter? = nil,
        metadata: ContentMetadata? = nil
    ) {
        self.type = type
        self.text = text
        self.code = code
        self.inlineCode = inlineCode
        self.emphasis = emphasis
        self.strong = strong
        self.newlines = newlines
        self.url = url
        self.identifier = identifier
        self.heading = heading
        self.imageURL = imageURL
        self.aspectRatio = aspectRatio
        self.caption = caption
        self.appExtension = appExtension
        self.enabled = enabled
        self.technology = technology
        self.content = content
        self.parameters = parameters
        self.returns = returns
        self.thrown = thrown
        self.metadata = metadata
    }
}

/// Represents source code payloads that may be single strings or arrays
public enum CodeValue: Codable {
    case string(String)
    case lines([String])

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else if let linesValue = try? container.decode([String].self) {
            self = .lines(linesValue)
        } else {
            throw DecodingError.typeMismatch(
                String.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Expected string or array of strings for code value."
                )
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .lines(let lines):
            try container.encode(lines)
        }
    }

    /// Returns the code payload as a single string joined by newlines.
    public var text: String {
        switch self {
        case .string(let value):
            return value
        case .lines(let lines):
            return lines.joined(separator: "\n")
        }
    }
}

/// Represents a parameter in method signatures
public struct Parameter: Codable {
    public let name: String
    public let content: [TextFragment]?

    public init(name: String, content: [TextFragment]? = nil) {
        self.name = name
        self.content = content
    }
}

/// Represents content metadata
public struct ContentMetadata: Codable {
    public let platforms: [String]?

    public init(platforms: [String]? = nil) {
        self.platforms = platforms
    }
}

/// Represents variant information for different platforms/technologies
public struct Variant: Codable {
    public let traits: [VariantTrait]
    public let paths: [String]

    public init(traits: [VariantTrait], paths: [String]) {
        self.traits = traits
        self.paths = paths
    }
}

/// Represents an individual variant trait (e.g., interface language)
public struct VariantTrait: Codable {
    public let values: [String: String]

    public init(values: [String: String]) {
        self.values = values
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.values = try container.decode([String: String].self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(values)
    }

    public var interfaceLanguage: String? { values["interfaceLanguage"] }
    public var platform: String? { values["platform"] }
}

// MARK: - Content Item Types

/// Primary content sections (main content)
public struct PrimaryContentSection: Codable {
    public let kind: String?
    public let title: String?
    public let content: [TextFragment]?
    public let anchor: String?

    public init(kind: String? = nil, title: String? = nil, content: [TextFragment]? = nil, anchor: String? = nil) {
        self.kind = kind
        self.title = title
        self.content = content
        self.anchor = anchor
    }
}

/// Topic sections for related content
public struct TopicSection: Codable {
    public let title: String
    public let identifiers: [String]
    public let generated: Bool?

    public init(title: String, identifiers: [String], generated: Bool? = nil) {
        self.title = title
        self.identifiers = identifiers
        self.generated = generated
    }
}

/// Main content item structure
public struct ContentItem: Codable {
    public let kind: String?
    public let title: String?
    public let role: String?
    public let deprecated: Bool?
    public let intro: [TextFragment]?
    public let sections: [ContentSection]?
    public let topicSections: [TopicSection]?
    public let primaryContentSections: [PrimaryContentSection]?
    public let relationshipsSections: [RelationshipsSection]?
    public let seeAlsoSections: [SeeAlsoSection]?
    public let deprecationSummary: [TextFragment]?
    public let downloadNotAvailableMessage: [TextFragment]?
    public let availability: [AvailabilityInfo]?

    public init(
        kind: String? = nil,
        title: String? = nil,
        role: String? = nil,
        deprecated: Bool? = nil,
        intro: [TextFragment]? = nil,
        sections: [ContentSection]? = nil,
        topicSections: [TopicSection]? = nil,
        primaryContentSections: [PrimaryContentSection]? = nil,
        relationshipsSections: [RelationshipsSection]? = nil,
        seeAlsoSections: [SeeAlsoSection]? = nil,
        deprecationSummary: [TextFragment]? = nil,
        downloadNotAvailableMessage: [TextFragment]? = nil,
        availability: [AvailabilityInfo]? = nil
    ) {
        self.kind = kind
        self.title = title
        self.role = role
        self.deprecated = deprecated
        self.intro = intro
        self.sections = sections
        self.topicSections = topicSections
        self.primaryContentSections = primaryContentSections
        self.relationshipsSections = relationshipsSections
        self.seeAlsoSections = seeAlsoSections
        self.deprecationSummary = deprecationSummary
        self.downloadNotAvailableMessage = downloadNotAvailableMessage
        self.availability = availability
    }
}

/// Content section within an item
public struct ContentSection: Codable {
    public let kind: String?
    public let title: String?
    public let abstract: [TextFragment]?
    public let content: [TextFragment]?
    public let identifier: String?

    public init(kind: String? = nil, title: String? = nil, abstract: [TextFragment]? = nil, content: [TextFragment]? = nil, identifier: String? = nil) {
        self.kind = kind
        self.title = title
        self.abstract = abstract
        self.content = content
        self.identifier = identifier
    }
}

/// Relationships section
public struct RelationshipsSection: Codable {
    public let kind: String?
    public let title: String?
    public let identifiers: [String]?
    public let type: String?
    public let anchor: String?

    public init(kind: String? = nil, title: String? = nil, identifiers: [String]? = nil, type: String? = nil, anchor: String? = nil) {
        self.kind = kind
        self.title = title
        self.identifiers = identifiers
        self.type = type
        self.anchor = anchor
    }
}

/// See also section
public struct SeeAlsoSection: Codable {
    public let title: String?
    public let destinations: [Destination]?
    public let generated: Bool?
    public let anchor: String?

    public init(title: String? = nil, destinations: [Destination]? = nil, generated: Bool? = nil, anchor: String? = nil) {
        self.title = title
        self.destinations = destinations
        self.generated = generated
        self.anchor = anchor
    }
}

/// Destination for related content
public struct Destination: Codable {
    public let title: String?
    public let url: String?
    public let identifier: String?
    public let kind: String?

    public init(title: String? = nil, url: String? = nil, identifier: String? = nil, kind: String? = nil) {
        self.title = title
        self.url = url
        self.identifier = identifier
        self.kind = kind
    }
}

/// Availability information
public struct AvailabilityInfo: Codable {
    public let name: String?
    public let introduced: String?
    public let deprecated: Bool?
    public let message: String?

    public init(name: String? = nil, introduced: String? = nil, deprecated: Bool? = nil, message: String? = nil) {
        self.name = name
        self.introduced = introduced
        self.deprecated = deprecated
        self.message = message
    }
}

/// Metadata entry for platform availability
public struct DocumentationPlatform: Codable {
    public let name: String?
    public let introducedAt: String?
    public let current: String?

    public init(name: String? = nil, introducedAt: String? = nil, current: String? = nil) {
        self.name = name
        self.introducedAt = introducedAt
        self.current = current
    }
}

/// Documentation metadata
public struct DocumentationMetadata: Codable {
    public let color: String?
    public let role: String?
    public let roleHeading: String?
    public let platforms: [DocumentationPlatform]?
    public let title: String?
    public let symbolVariant: String?

    public init(
        color: String? = nil,
        role: String? = nil,
        roleHeading: String? = nil,
        platforms: [DocumentationPlatform]? = nil,
        title: String? = nil,
        symbolVariant: String? = nil
    ) {
        self.color = color
        self.role = role
        self.roleHeading = roleHeading
        self.platforms = platforms
        self.title = title
        self.symbolVariant = symbolVariant
    }
}

// MARK: - Main Response Type

/// Root type representing Apple documentation JSON response
public struct AppleDocumentation: Codable {
    public let metadata: DocumentationMetadata?
    public let abstract: [TextFragment]?
    public let sections: [ContentItem]?
    public let primaryContentSections: [PrimaryContentSection]?
    public let topicSections: [TopicSection]?
    public let relationshipsSections: [RelationshipsSection]?
    public let seeAlsoSections: [SeeAlsoSection]?
    public let variants: [Variant]?
    public let identifier: DocumentationIdentifier?
    public let schemaVersion: VersionInfo?
    public let kind: String?
    public let url: String?

    public init(
        metadata: DocumentationMetadata? = nil,
        abstract: [TextFragment]? = nil,
        sections: [ContentItem]? = nil,
        primaryContentSections: [PrimaryContentSection]? = nil,
        topicSections: [TopicSection]? = nil,
        relationshipsSections: [RelationshipsSection]? = nil,
        seeAlsoSections: [SeeAlsoSection]? = nil,
        variants: [Variant]? = nil,
        identifier: DocumentationIdentifier? = nil,
        schemaVersion: VersionInfo? = nil,
        kind: String? = nil,
        url: String? = nil
    ) {
        self.metadata = metadata
        self.abstract = abstract
        self.sections = sections
        self.primaryContentSections = primaryContentSections
        self.topicSections = topicSections
        self.relationshipsSections = relationshipsSections
        self.seeAlsoSections = seeAlsoSections
        self.variants = variants
        self.identifier = identifier
        self.schemaVersion = schemaVersion
        self.kind = kind
        self.url = url
    }
}

/// Identifier information for documentation nodes
public struct DocumentationIdentifier: Codable {
    public let url: String?
    public let interfaceLanguage: String?

    public init(url: String? = nil, interfaceLanguage: String? = nil) {
        self.url = url
        self.interfaceLanguage = interfaceLanguage
    }
}

/// Version information for the documentation schema
public struct VersionInfo: Codable {
    public let major: Int?
    public let minor: Int?
    public let patch: Int?

    public init(major: Int? = nil, minor: Int? = nil, patch: Int? = nil) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }
}

// MARK: - Search Results

/// Search result item for documentation search
public struct DocumentationSearchResult: Codable, Hashable {
    public let title: String
    public let url: String
    public let type: String
    public let description: String?
    public let identifier: String?

    public init(title: String, url: String, type: String, description: String? = nil, identifier: String? = nil) {
        self.title = title
        self.url = url
        self.type = type
        self.description = description
        self.identifier = identifier
    }
}

/// Framework documentation index response
public struct FrameworkIndex: Codable {
    public let name: String
    public let url: String
    public let kind: String
    public let role: String
    public let abstract: [TextFragment]?

    public init(name: String, url: String, kind: String, role: String, abstract: [TextFragment]? = nil) {
        self.name = name
        self.url = url
        self.kind = kind
        self.role = role
        self.abstract = abstract
    }
}
