---
name: sosumi
description: Search Apple developer documentation and WWDC sessions. Automatically triggers on Apple frameworks (SwiftUI, Combine, Core Data, UIKit, AppKit), Apple APIs, @State/@Published, async/await, visionOS, iOS SDK, and WWDC questions. Does NOT cover third-party packages (use scully) or personal discoveries (use maxwell).
allowed-tools: Bash, Read, Write, Glob
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
/skill sosumi doc "https://developer.apple.com/documentation/groupactivities/adding-spatial-persona-support-to-an-activity"
/skill sosumi doc "doc://com.apple.documentation/videos/play/wwdc2024/10201"
```

## 🚀 Quick Start - Universal Search

**For AI Agents (Recommended): Just use `sosumi search`**

```bash
# Works with anything - auto-detects what you want:
sosumi search "SharePlay"
sosumi search "SharePlay GroupActivities"
sosumi search "https://developer.apple.com/documentation/groupactivities/..."
sosumi search "https://developer.apple.com/videos/play/wwdc2024/10102/"
sosumi search "wwdc2024-10102"

### How sosumi search Routes Your Input

| Input Example                                                 | Detected As           | Routes To            | Result                        |
|---------------------------------------------------------------|-----------------------|----------------------|-------------------------------|
| SharePlay                                                     | Single word/framework | Documentation search | API docs for SharePlay        |
| SharePlay GroupActivities                                     | Multi-word query      | Combined search      | Both docs + WWDC sessions     |
| wwdc2024-10102                                                | Session ID            | Session lookup       | Full WWDC session transcript  |
| https://developer.apple.com/videos/play/wwdc2024/10102/       | Video URL             | Session fetch        | Extracts ID + fetches session |
| https://developer.apple.com/documentation/groupactivities/... | Doc URL               | Page fetch           | Fetches specific doc page     |
| groupactivities/adding-spatial-persona-support-to-an-activity | Doc path              | Page fetch           | Fetches specific doc page     |

### Alternative Commands (when you want to be specific)

- sosumi docs <query> - Force documentation search only
- sosumi wwdc <query> - Force WWDC search only
- sosumi doc <path> - Fetch specific documentation page
- sosumi session <id> - Get specific WWDC session

### ⚠️ **Troubleshooting Missing Content**

**Session ID not found?**
```bash
# Session format: wwdcYYYY-##### (5-digit session number)
/skill sosumi session wwdc2025-317    # ✅ Correct format
/skill sosumi session wwdc2025-9999   # ❌ Wrong format (too many digits)
/skill sosumi session wwdc2025-999    # ❌ Session doesn't exist
```

**Documentation URL not working?**
```bash
# Try removing query parameters or using path-only:
/skill sosumi doc "/documentation/groupactivities/joining-and-managing-a-shared-activity"

# Or search instead:
/skill sosumi docs "shared experiences groupactivities" --format compact
```

**Error messages mean:**
- "Session not found" = Session ID doesn't exist in the database
- "Documentation not found" = URL path is incorrect or content removed
- "No results found" = Search returned nothing (try different terms)

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
/skill sosumi docs <query> [--limit <number>] [--format <format>] [--intent <intent>] [--type <type>] [--requires <platforms>] [--time-estimate <minutes>]
```

Runs the live Apple documentation search with **intent-based filtering** and **agent-optimized efficiency**. Use when you need targeted documentation without knowing content type terminology.

**🚀 Agent Efficiency Features (NEW):**
- **Smart default limit**: 15 results (96% token savings vs unlimited)
- **Compact formats**: Maximum token efficiency for agent consumption
- **Relevance scores**: See result quality at a glance
- **"More results" hints**: Know when to request more

**🎯 Intent-Based Filtering:**
- `--intent <example|explain|reference|learn|all>` - Express what you want to accomplish
- **Automatic intent detection** - No flags needed for most queries
- **Smart ranking** - Results ranked by relevance to your intent

**📄 Output Formats:**
- `--format markdown` (default): Full structured output with headings
- `--format compact`: Token-efficient flat list (57% additional savings)
- `--format compact-scores`: Compact with relevance scores (recommended)
- `--format json`: Structured data for automation

**🔧 Expert Mode Filtering:**
- `--type <article|sampleCode|symbol|tutorial>` - Filter by content type
- `--requires <ios14,macos12>` - Require specific platform support
- `--time-estimate <15>` - Limit to content under X minutes

**🎯 Agent-Optimized Examples:**
```bash
# Most efficient for agents (recommended)
/skill sosumi docs "animation" --format compact-scores  # 15 results with scores
/skill sosumi docs "SwiftUI layout" --limit 10          # Precise result count
/skill sosumi docs "how to animate" --format compact     # Maximum efficiency

# Intent-based with efficiency
/skill sosumi docs "animation examples" --intent example --format compact-scores
/skill sosumi docs "explain animations" --intent explain --limit 8
/skill sosumi docs "animation API" --intent reference --format compact

# When you need comprehensive results
/skill sosumi docs "SwiftUI" --limit 50                    # More results when needed
/skill sosumi docs "all frameworks" --limit 100           # Large search with efficiency

# Smart defaults work automatically
/skill sosumi docs "SwiftUI animation"   # Auto-detects intent, uses efficient defaults
/skill sosumi docs "Button example"       # Boosts sample code, compact format

# Expert mode with efficiency
/skill sosumi docs "animation" --type sampleCode --format compact-scores

# Platform and time filtering
/skill sosumi docs "widgets" --requires ios17 --limit 10
/skill sosumi docs "SwiftUI" --intent learn --time-estimate 15 --format compact
```

**💡 Token Efficiency Tips:**
- Start with `--format compact-scores --limit 15` for optimal token usage
- Use `--limit <number>` instead of default when you know exactly what you need
- `--format compact-scores` gives you both efficiency AND quality indicators
- The system shows "X more results available" when you need comprehensive coverage

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

# Pass a full Apple URL (quote it if there are special characters)
/skill sosumi doc "https://developer.apple.com/documentation/groupactivities/adding-spatial-persona-support-to-an-activity"

# Use doc:// identifiers copied from Apple docs
/skill sosumi doc "doc://com.apple.documentation/videos/play/wwdc2024/10201"

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
