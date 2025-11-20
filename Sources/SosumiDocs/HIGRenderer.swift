import Foundation

public struct HIGRenderer {
    public init() {}

    public func renderPage(_ page: HIGPage, sourceURL: String) -> String {
        let references = page.references ?? [:]
        var markdown = ""
        markdown += frontMatter(for: page, sourceURL: sourceURL, references: references)
        markdown += breadcrumbs(for: sourceURL)

        if let role = page.metadata?.role, !role.isEmpty {
            let roleDisplay = role == "collectionGroup" ? "Guide Collection" : role
            markdown += "**\(roleDisplay)**\n\n"
        }

        if let title = page.metadata?.title, !title.isEmpty {
            markdown += "# \(title)\n\n"
        }

        if let abstract = page.abstract, !abstract.isEmpty {
            let abstractText = renderInlineContent(abstract, references: references).trimmingCharacters(in: .whitespacesAndNewlines)
            if !abstractText.isEmpty {
                markdown += "> \(abstractText)\n\n"
            }
        }

        if let sections = page.primaryContentSections {
            for section in sections {
                if let content = section.content {
                    markdown += renderContentItems(content, references: references)
                }
            }
        }

        if let sections = page.sections {
            markdown += renderContentItems(sections, references: references)
        }

        if
            let topicSections = page.topicSections,
            (page.topicSectionsStyle?.lowercased() ?? "list") != "hidden",
            !topicSections.isEmpty
        {
            markdown += "## Related Topics\n\n"
            for section in topicSections {
                if let title = section.title, !title.isEmpty {
                    markdown += "### \(title)\n"
                }
                if let identifiers = section.identifiers {
                    for identifier in identifiers {
                        markdown += renderReferenceListEntry(identifier, references: references)
                    }
                }
                markdown += "\n"
            }
        }

        markdown = markdown.trimmingCharacters(in: .whitespacesAndNewlines)
        markdown += "\n\n---\n\n"
        markdown += "*Extracted by sosumi — unofficial rendering of Apple's Human Interface Guidelines.*\n"
        return markdown
    }

    public func renderTableOfContents(_ toc: HIGTableOfContents) -> String {
        var markdown = ""
        markdown += "---\n"
        markdown += "title: Human Interface Guidelines\n"
        markdown += "description: Apple's Human Interface Guidelines - Complete table of contents\n"
        markdown += "source: https://developer.apple.com/design/human-interface-guidelines/\n"
        markdown += "timestamp: \(ISO8601DateFormatter().string(from: Date()))\n"
        markdown += "---\n\n"
        markdown += "# Human Interface Guidelines\n\n"
        markdown += "> Apple's comprehensive guide to designing interfaces for all Apple platforms.\n\n"

        if let entries = toc.interfaceLanguages?.swift {
            markdown += renderTocItems(entries, depth: 0)
        }

        markdown += "\n\n---\n\n"
        markdown += "*Extracted by sosumi — unofficial rendering of Apple's Human Interface Guidelines.*\n"
        return markdown
    }

    // MARK: - Private Helpers

    private func frontMatter(
        for page: HIGPage,
        sourceURL: String,
        references: [String: HIGReferenceValue]
    ) -> String {
        var frontMatter: [String: String] = [:]
        if let title = page.metadata?.title {
            frontMatter["title"] = title
        }

        if let abstract = page.abstract, !abstract.isEmpty {
            let description = renderInlineContent(abstract, references: references)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !description.isEmpty {
                frontMatter["description"] = description
            }
        }

        frontMatter["source"] = sourceURL
        frontMatter["timestamp"] = ISO8601DateFormatter().string(from: Date())

        let yaml = frontMatter
            .map { "\($0.key): \($0.value)" }
            .joined(separator: "\n")
        return "---\n\(yaml)\n---\n\n"
    }

    private func breadcrumbs(for sourceURL: String) -> String {
        guard let url = URL(string: sourceURL) else { return "" }
        let pathParts = url.path.split(separator: "/")
        guard pathParts.count >= 3 else { return "" }

        var breadcrumb = "**Navigation:** [Human Interface Guidelines](/design/human-interface-guidelines)"
        if pathParts.count > 3 {
            for idx in 3..<pathParts.count {
                let part = pathParts[idx]
                let formatted = part.replacingOccurrences(of: "-", with: " ").capitalized
                let path = "/" + pathParts[0...idx].joined(separator: "/")
                breadcrumb += " › [\(formatted)](\(path))"
            }
        }

        return "\(breadcrumb)\n\n"
    }

    private func renderContentItems(_ items: [HIGContentNode], references: [String: HIGReferenceValue]) -> String {
        items.reduce(into: "") { output, item in
            output += renderContentItem(item, references: references)
        }
    }

    private func renderContentItem(_ item: HIGContentNode, references: [String: HIGReferenceValue]) -> String {
        guard let type = item.type?.lowercased() else {
            if let content = item.content {
                return renderContentItems(content, references: references)
            }
            return ""
        }

        switch type {
        case "paragraph":
            let text = renderInlineContent(item.inlineContent ?? [], references: references)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return text.isEmpty ? "" : "\(text)\n\n"

        case "heading":
            let headingText = item.text ?? item.title ?? ""
            guard !headingText.isEmpty else { return "" }
            let level = min(max(item.level ?? 2, 1), 6)
            return "\(String(repeating: "#", count: level)) \(headingText)\n\n"

        case "links":
            guard let identifiers = item.items else { return "" }
            var output = ""
            for identifier in identifiers {
                output += renderReferenceListEntry(identifier, references: references)
            }
            return output + "\n"

        case "row":
            guard let columns = item.columns else { return "" }
            return columns.compactMap { column in
                guard let content = column.content else { return nil }
                return renderContentItems(content, references: references)
            }.joined()

        case "aside":
            let text: String
            if let content = item.content {
                text = renderContentItems(content, references: references)
            } else if let inline = item.inlineContent {
                text = renderInlineContent(inline, references: references)
            } else {
                text = ""
            }
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return "" }
            let quoted = trimmed.replacingOccurrences(of: "\n", with: "\n> ")
            return "> \(quoted)\n\n"

        case "tabnavigator":
            guard let tabs = item.tabs else { return "" }
            var output = ""
            for tab in tabs {
                if let title = tab.title {
                    output += "### \(title)\n\n"
                }
                if let content = tab.content {
                    output += renderContentItems(content, references: references)
                }
            }
            return output

        case "table":
            return renderTable(item, references: references)

        default:
            if let content = item.content {
                return renderContentItems(content, references: references)
            } else if let inline = item.inlineContent {
                let text = renderInlineContent(inline, references: references)
                return text.isEmpty ? "" : "\(text)\n\n"
            }
            return ""
        }
    }

    private func renderInlineContent(_ nodes: [HIGContentNode], references: [String: HIGReferenceValue]) -> String {
        var builder = ""
        for node in nodes {
            let type = node.type?.lowercased()
            switch type {
            case "text":
                builder += node.text ?? ""
            case "codevoice":
                let code = node.code ?? node.text ?? ""
                builder += "`\(code)`"
            case "reference":
                if let identifier = node.identifier {
                    builder += renderReferenceInline(identifier: identifier, references: references)
                } else if let url = node.url, let text = node.text {
                    let normalized = normalizedURL(url)
                    builder += "[\(text)](\(normalized))"
                } else {
                    builder += node.text ?? ""
                }
            case "emphasis":
                let inner = renderInlineContent(node.inlineContent ?? [], references: references)
                builder += "*\(inner)*"
            case "strong":
                let inner = renderInlineContent(node.inlineContent ?? [], references: references)
                builder += "**\(inner)**"
            case "image":
                if let identifier = node.identifier,
                   let imageURL = imageURL(for: identifier, references: references) {
                    builder += "![\(identifier)](\(imageURL))"
                }
            default:
                if let inline = node.inlineContent {
                    builder += renderInlineContent(inline, references: references)
                } else if let text = node.text {
                    builder += text
                }
            }
        }
        return builder
    }

    private func renderReferenceInline(identifier: String, references: [String: HIGReferenceValue]) -> String {
        if let reference = references[identifier], !reference.isImageReference {
            let title = reference.title ?? identifier
            if let url = reference.url {
                return "[\(title)](\(normalizedURL(url)))"
            } else {
                return title
            }
        } else if identifier.hasPrefix("http") {
            return "[\(identifier)](\(identifier))"
        } else {
            return identifier
        }
    }

    private func renderReferenceListEntry(_ identifier: String, references: [String: HIGReferenceValue]) -> String {
        guard let reference = references[identifier], !reference.isImageReference else { return "" }
        let title = reference.title ?? identifier
        var line = "- [\(title)]"
        if let url = reference.url {
            line += "(\(normalizedURL(url)))"
        }
        if let abstract = reference.abstract, !abstract.isEmpty {
            let summary = renderInlineContent(abstract, references: references)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !summary.isEmpty {
                line += " - \(summary)"
            }
        }
        return line + "\n"
    }

    private func renderTable(_ node: HIGContentNode, references: [String: HIGReferenceValue]) -> String {
        guard let rows = node.rows, !rows.isEmpty else { return "" }
        var output = ""

        func renderCells(_ cells: [[HIGContentNode]]) -> [String] {
            cells.map { cell in
                renderInlineContent(cell, references: references)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        let headerCells = renderCells(rows[0])
        guard !headerCells.isEmpty else { return "" }
        output += "|" + headerCells.map { " \($0) " }.joined(separator: "|") + "|\n"
        output += "|" + headerCells.map { String(repeating: "-", count: max($0.count, 3)) }.joined(separator: "|") + "|\n"

        for row in rows.dropFirst() {
            let values = renderCells(row)
            output += "|" + values.map { " \($0) " }.joined(separator: "|") + "|\n"
        }

        output += "\n"
        return output
    }

    private func renderTocItems(_ items: [HIGTocItem], depth: Int) -> String {
        guard !items.isEmpty else { return "" }
        var markdown = ""
        for item in items {
            let indent = String(repeating: "  ", count: depth)
            let title = item.title ?? "Untitled"
            if let path = item.path, !path.isEmpty {
                let displayPath = normalizedURL(path)
                markdown += "\(indent)- [\(title)](\(displayPath))\n"
            } else {
                markdown += "\(indent)- \(title)\n"
            }
            if let children = item.children {
                markdown += renderTocItems(children, depth: depth + 1)
            }
        }
        return markdown
    }

    private func imageURL(for identifier: String, references: [String: HIGReferenceValue]) -> String? {
        guard let reference = references[identifier], let variant = reference.variants?.first else {
            return nil
        }
        return variant.url
    }

    private func normalizedURL(_ url: String) -> String {
        return DocURLUtilities.toWebURL(url) ?? url
    }
}
