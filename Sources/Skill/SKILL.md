---
name: sosumi
description: Apple API documentation and WWDC sessions. Searches Swift, SwiftUI, UIKit, RealityKit, Combine, Foundation, CoreData, URLSession, AVFoundation, visionOS APIs. Gets method signatures, code examples, WWDC transcripts (2018-2025). Use for "How do I use [API]?", "What's the signature for playAnimation?", "WWDC about RealityKit", "AnimationPlaybackController example", "GroupActivities API", framework documentation, Apple code samples.
allowed-tools: [WebSearch, Read, Bash, Write, Edit, Grep, Glob]
---

# Sosumi - Apple Documentation & WWDC Skill

**Comprehensive access to Apple's entire developer ecosystem** with real-time API documentation, searchable WWDC transcripts (2018-2025), code examples, and design guidelines.

## When to Use Sosumi

**Automatically triggered for:**
- ✅ API method/function lookups ("What's the signature for playAnimation()?")
- ✅ Framework documentation ("How do I use RealityKit?")
- ✅ WWDC session searches ("Show me WWDC about RealityComposer Pro")
- ✅ Code examples ("Example of AnimationPlaybackController usage")
- ✅ Swift API references ("SwiftUI View properties", "Combine operators")
- ✅ Apple best practices ("How does Apple recommend...")
- ✅ Timeline/animation APIs ("AnimationResource", "PlaybackController")

**Manual trigger:** `/skill sosumi search <query>`

### What Sosumi Provides

- **📚 Apple Documentation** - Swift language, SwiftUI, UIKit, Core Data, and 50+ frameworks
- **🎥 WWDC Content** - Session transcripts 2018-2025, searchable and cached
- **🎨 Design Guidelines** - Human Interface Guidelines for all platforms
- **🔍 Intelligent Search** - Unified search across all content types
- **⚡ Real-Time + Cached** - Live Apple API access + fast cached WWDC content

## Trigger Detection

Sosumi is automatically invoked when queries contain any of:

**Framework names:**
- Core frameworks: `SwiftUI`, `Combine`, `Foundation`, `Concurrency`
- Platform-specific: `UIKit`, `AppKit`, `WatchKit`, `RealityKit`, `visionOS`
- Data/Storage: `CoreData`, `CloudKit`, `SQLite`, `UserDefaults`
- Networking: `URLSession`, `Network`, `WebSocket`
- Media: `AVFoundation`, `Vision`, `CoreML`, `ImageIO`
- Graphics: `Metal`, `SceneKit`, `SpriteKit`, `OpenGL`
- Spatial: `ARKit`, `CoreLocation`, `MapKit`, `SensorKit`
- Developer tools: `Xcode`, `SwiftSyntax`, `Testing`, `Instruments`

**Query patterns:**
- API lookups: "What's the signature for...", "How do I use...", "Methods for..."
- Framework questions: "SwiftUI animation", "Combine operators", "RealityKit timeline"
- Code examples: "Example of...", "Show me how to...", "Code sample for..."
- WWDC searches: "WWDC session on...", "Apple showed...", "How does Apple recommend..."
- Apple best practices: "Apple's way to...", "Official documentation for..."

**Common examples (full list):**
- "What does `@State` do?" → Auto-triggers
- "How do I use Combine with async/await?" → Auto-triggers
- "Show me URLSession code example" → Auto-triggers
- "Author timelines in Reality Composer Pro" → Auto-triggers
- "WWDC about SwiftUI navigation" → Auto-triggers
- "GroupActivities API reference" → Auto-triggers
- "CloudKit sync patterns" → Auto-triggers
- "RealityKit AnimationPlaybackController" → Auto-triggers

**If sosumi doesn't trigger automatically, use explicit command:**
```bash
/skill sosumi search "your query"
/skill sosumi wwdc "topic"
/skill sosumi doc framework/api
```

## Quick Start

```bash
# Combined docs + WWDC search (default)
/skill sosumi search "SwiftUI animations"

# Documentation-only search
/skill sosumi search "URLSession metrics" --type docs
/skill sosumi docs "Combine scheduler" --limit 3

# Fetch a specific documentation page
/skill sosumi doc swiftui/view
/skill sosumi doc groupactivities/drawing_content_in_a_group_session --format markdown

# Search WWDC content
/skill sosumi wwdc "GroupActivities"

# Search for RealityKit/Timeline content
/skill sosumi search "Reality Composer Pro timeline animation"
/skill sosumi wwdc "RealityComposer Pro"

# Update bundled data
/skill sosumi update --force

# Build search indexes
/skill sosumi index
```

### Platform Naming Reference

| Term you may see | How Sosumi interprets it | Notes |
|------------------|-------------------------|-------|
| `visionOS 26`    | Latest visionOS release announced at WWDC 2025 (session IDs `wwdc2025-3xx`) | **Do not** rewrite it as “visionOS 2.0”. Use the wording the user provides. |
| `iOS 26` / `iPadOS 26` | 2025 platform releases | Treat as current versions (session IDs `wwdc2025-1xxx`). |
| `macOS 26` / `Tahoe` | Latest macOS release | Accept codename or version number interchangeably. |
| `watchOS 26` | Latest Apple Watch release | Use as provided. |
| `tvOS 26` | Latest Apple TV release | Use as provided. |
| `wwdcYYYY-#####` | Canonical content ID (e.g., `wwdc2024-10150`) | Ask the user for the full ID if they only provide the numeric part. |

> **Agent guidance:** When a user references “visionOS 26” or similar terms from WWDC 2025, treat them literally—run `sosumi wwdc "visionOS 26" ...` rather than “correcting” the terminology.

## Features

### 📖 Documentation Access
- **Real-time API access** to Apple's undocumented JSON endpoints
- **Comprehensive coverage** of all Apple frameworks and Swift language
- **Offline capability** with bundled core documentation
- **Smart caching** for optimal performance

### 🎬 WWDC Integration
- **Full transcript access** from all WWDC sessions
- **Insight extraction** and key topic identification
- **Session recommendations** based on topics
- **Cross-referencing** with related documentation

### 🔍 Advanced Search
- **Unified search** across docs, WWDC, and HIG
- **Context-aware results** with relevance scoring
- **Type-based filtering** (docs, WWDC, design)
- **Content preview** and quick summaries

### ⚡ Performance Features
- **Hybrid storage**: Memory cache + Disk cache + Bundled data
- **Compression**: Gzip compression for 70-90% size reduction
- **Progressive loading**: Load only relevant content
- **Smart indexing**: Fast search across large datasets

## Commands

### Search Commands

#### Basic Search
```bash
/skill sosumi search <query> [--type <docs|wwdc|combined>] [--limit <number>]
```

**Examples:**
```bash
# Combined search (docs + WWDC)
/skill sosumi search "SwiftUI animations" --limit 5

# Documentation-only search
/skill sosumi search "URLSession" --type docs

# WWDC sessions only
/skill sosumi search "Combine framework" --type wwdc
```

The `search` command defaults to a **combined view** (Apple docs + WWDC). Use `--type docs` or `--type wwdc` to scope. `--limit` controls both sections; override one side with `--docs-limit` or `--wwdc-limit`.

#### Documentation Search (`docs`)
```bash
/skill sosumi docs <query> [--limit <number>]
```

Runs the live Apple documentation search directly (same as `sosumi docs`). Use when you only need API references without WWDC output.

#### Documentation Fetch
```bash
/skill sosumi doc <path> [--format <json|markdown>]
```

**Examples:**
```bash
# Get SwiftUI View documentation
/skill sosumi doc swiftui/view

# Get Swift Language Guide
/skill sosumi doc swift/language-guide

# Get in JSON format
/skill sosumi doc combine/publisher --format json
```

> `fetch` remains an alias for `doc` if older instructions/scripts still reference it.

#### WWDC Content
```bash
/skill sosumi wwdc <query> [--session <session-id>]
```

**Examples:**
```bash
# Search WWDC sessions about SwiftUI
/skill sosumi wwdc "SwiftUI"

# Get specific session transcript
/skill sosumi wwdc --session wwdc2022-10056

# Find sessions about specific frameworks
/skill sosumi wwdc "Core Data performance"
```

### Management Commands

#### Update Bundled Data
```bash
/skill sosumi update [--force]
```

Updates the bundled documentation with the latest Apple content. Use `--force` to override existing data.

#### Build Search Index
```bash
/skill sosumi index [--directory <path>]
```

Builds or rebuilds the search index from bundled data for faster searches.

#### Performance Analysis
```bash
/skill sosumi performance
```

Shows search performance metrics and cache statistics.

#### Cache Management
```bash
/skill sosumi cache clear
/skill sosumi cache stats
```

Clear cache or show cache usage statistics.

## Search Tips

### Effective Queries
- **Be specific**: "SwiftUI List animations" vs "animations"
- **Use framework names**: "Combine", "SwiftUI", "CoreData"
- **Include platform**: "iOS notification", "macOS window"
- **Use quotes** for exact phrases: "GroupActivities framework"

### Content Types
- `documentation`: Apple API documentation and guides
- `wwdc`: WWDC session transcripts and videos
- `hig`: Human Interface Guidelines
- `sampleCode`: Code examples and sample projects

### Search Operators
- **Type filtering**: `--type wwdc` to search only WWDC content
- **Limit results**: `--limit 5` for fewer, more relevant results
- **Context hints**: Include iOS/macOS/SwiftUI for better targeting

## Examples

### Finding SharePlay/Group Activities Information
```bash
# Combined docs + WWDC search
/skill sosumi search "SharePlay" --limit 5

# Specific framework search
/skill sosumi search "GroupActivities framework" --type docs

# WWDC sessions on the topic
/skill sosumi wwdc "SharePlay activities"

# Get specific API documentation
/skill sosumi doc groupactivities/groupactivity
```

### Learning SwiftUI
```bash
# Get SwiftUI overview
/skill sosumi doc swiftui

# Search specific SwiftUI topics
/skill sosumi search "SwiftUI navigation stack" --limit 3

# Find related WWDC sessions
/skill sosumi wwdc "SwiftUI layout system"
```

### Framework Migration
```bash
# UIKit to SwiftUI equivalents
/skill sosumi search "UIKit equivalent SwiftUI"

# Compare implementations
/skill sosumi search "UITableView SwiftUI List"
```

### RealityKit Timeline Animation (RCP)
```bash
# Get AnimationPlaybackController API
/skill sosumi search "AnimationPlaybackController" --type documentation

# Find WWDC sessions on RealityComposer Pro
/skill sosumi wwdc "RealityComposer Pro timeline"

# Get AnimationResource documentation
/skill sosumi doc realitykit/animationresource

# Search for timeline playback patterns
/skill sosumi search "Reality Composer Pro timeline animation playback"

# WWDC guidance on RCP animations
/skill sosumi wwdc "RealityKit animation" --limit 5
```

## Performance

The sosumi skill is optimized for performance with:

- **Memory caching**: Frequently accessed content stays in memory
- **Disk caching**: Less frequent content cached on disk
- **Bundled data**: Core documentation included offline
- **Smart compression**: 70-90% size reduction for bundled content
- **Progressive loading**: Only load content you need

### Typical Performance
- **Local search**: 1-50ms (cached content)
- **API search**: 500-2000ms (live content)
- **Documentation fetch (`doc`)**: 200-1000ms
- **WWDC transcript**: 100-500ms

## Data Sources

### Apple Documentation
- **Swift Language** - Language guide, standard library, concurrency
- **Apple Frameworks** - SwiftUI, UIKit, AppKit, Foundation, Combine
- **visionOS** - Spatial computing, RealityKit, ARKit
- **Developer Tools** - Xcode, SwiftSyntax, testing frameworks

### WWDC Content
- **Session Transcripts** - Full text transcripts with timing
- **Session Metadata** - Topics, speakers, platforms, year
- **Code Examples** - Sample code from presentations
- **Related Content** - Links to documentation and resources

### Human Interface Guidelines
- **Design Principles** - Core Apple design philosophy
- **Platform Guidelines** - iOS, macOS, visionOS specifics
- **Pattern Library** - Navigation, input, interaction patterns

## Technical Details

### Architecture
- **Swift-based** implementation for optimal performance
- **Hybrid caching** with memory, disk, and bundled storage
- **Compressed storage** using gzip for efficient data usage
- **Intelligent indexing** for fast search across large datasets
- **MCP integration** for seamless Claude Code interaction

### Data Compression
- **JSON compression**: 70-90% size reduction
- **Efficient storage**: Only decompress when needed
- **Smart caching**: LRU eviction policies
- **Background updates**: Annual content refresh

### Search Technology
- **Term extraction**: Intelligent keyword identification
- **Relevance scoring**: Title and content weighting
- **Type-aware search**: Filter by content type
- **Cross-referencing**: Link related content automatically

## Troubleshooting

### Common Issues

**Slow search results?**
- Run `/skill sosumi performance` to check cache stats
- Consider updating bundled data with `/skill sosumi update`
- Check internet connectivity for live content

**Missing content?**
- Use `/skill sosumi update --force` to refresh bundled data
- Try more specific search terms
- Check if content type filter is too restrictive

**Search not working?**
- Run `/skill sosumi index` to rebuild search indexes
- Clear cache with `/skill sosumi cache clear`
- Check network connectivity for API access

### Debug Information
```bash
# Check system status
/skill sosumi performance

# Cache statistics
/skill sosumi cache stats

# Validate index
/skill sosumi index --validate
```

## Updates

### Content Updates
- **Annual refresh**: Core documentation updated yearly
- **Live content**: Always current via Apple APIs
- **WWDC sessions**: Added throughout conference season
- **Framework additions**: New frameworks added when released

### Performance Improvements
- **Caching optimization**: Continuous cache improvement
- **Search algorithm**: Enhanced relevance scoring
- **Compression techniques**: Better data compression
- **Index strategies**: Faster search methods

---

*Generated with sosumi - Making Apple docs AI-readable*
