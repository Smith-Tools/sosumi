# sosumi – Apple Documentation & WWDC Search

> **Real-time Apple documentation fetch + local WWDC transcript search for users and AI agents.**

sosumi combines two data paths:

- **Live Apple Documentation** – hits Apple’s undocumented JSON endpoints for any path or keyword (`sosumi docs`, `sosumi doc`). Results render to Markdown/JSON and include code listings, availability, and platform metadata.
- **Local WWDC Database** – ships an encrypted SQLite bundle (2018‑2025) with FTS5 search, dual user/agent renderers, and transcript access (`sosumi wwdc`, `session`, `year`).

Both paths are exposed through the CLI and the Claude skill so agents can mix official docs with WWDC guidance in a single response.

## ⚠️ Important: Development vs Production Builds

**This matters - please read:**

| Scenario | What to Do | What You Get |
|----------|-----------|-------------|
| **You just want to use sosumi** | Download production binary from [Releases](https://github.com/Smith-Tools/sosumi/releases) | ✅ Full WWDC search, real data, instant setup |
| **You're contributing/developing** | Clone repo, build from source | ⚠️ Dev build with fake data (see below) |
| **You're using in Claude Code** | Install production binary as skill | ✅ Full integration, no configuration |

### Why This Matters

**Production Build** (downloaded binary):
- ✅ Full WWDC transcript database (2018-2025)
- ✅ Real searchable session data
- ✅ Live Apple documentation search/fetch enabled
- ✅ Works instantly - no configuration needed
- ✅ Data is encrypted and embedded in binary
- 🎯 **This is what you want if you're a user**

**Development Build** (cloned from source):
- ⚠️ Uses **fake/mock data** for WWDC testing
- ⚠️ WWDC search returns placeholder results
- ⚠️ Cannot decrypt real encrypted data without production key
- ✅ Apple documentation search still works (hits live endpoints)
- ✅ Used for feature development and testing
- 🎯 **This is what developers need - not intended for users**

**If you clone the repo and WWDC search doesn't work, this is expected.** Use the production binary instead.

## 🎯 What is sosumi-skill?

sosumi provides two distinct search modes:

### 👥 User Mode
- **Quick summaries** with key points
- **Apple video links** for full sessions
- **Performance optimized** for human reading
- **Fast search** with relevance scoring

### 🤖 Agent Mode
- **Full transcripts** in Markdown format
- **Complete session metadata** (speakers, topics, duration)
- **AI-friendly formatting** for synthesis
- **Structured data** in JSON option

### 📚 Coverage
- **Live Apple documentation search** (Swift, SwiftUI, UIKit, Combine, RealityKit, etc.)
- **WWDC sessions** 2014‑2025 (3,216 entries; 1,355 transcripts with speakers)
- **Encrypted SQLite bundle** (~850 MB release artifact, ~166 MB uncompressed)
- **Dual renderers** (compact vs agent) + Markdown/JSON output

## 🚀 Quick Start

### For Users: Download Production Binary

```bash
# Download latest release and make executable
wget https://github.com/Smith-Tools/sosumi/releases/latest/download/sosumi-macos
chmod +x sosumi-macos

# Live Apple documentation search
./sosumi-macos docs "SwiftUI layout" --limit 5

# Fetch a specific doc page
./sosumi-macos doc swiftui/view

# WWDC search (user mode)
./sosumi-macos wwdc "SwiftUI animations"

# WWDC search (agent/full transcript)
./sosumi-macos wwdc "SharePlay" --verbosity full --format json
```

**That's it. No configuration needed. Production binaries include the encrypted WWDC bundle and ship with live doc capabilities enabled.**

### For Claude Code Users

```bash
# Install the production binary or run Scripts/deploy-skill.sh
mkdir -p ~/.claude/skills/sosumi

# Once installed:
/skill sosumi search "visionOS timeline"            # Combined docs + WWDC
/skill sosumi search "URLSession metrics" --type docs
/skill sosumi doc swiftui/app
/skill sosumi wwdc "GroupActivities"
```

### For Developers: Clone & Build

```bash
# Clone repository
git clone https://github.com/Smith-Tools/sosumi.git
cd sosumi

# Build (uses fake/mock data for development)
swift build

# Run tests
swift test

# ⚠️ WWDC search returns mock data (expected in dev)
swift run sosumi wwdc "async await"

# ✅ Apple documentation search still hits live endpoints
swift run sosumi docs "SwiftUI" --limit 5
```

**Note**: Development builds use fake data intentionally. This allows developers to work on features without access to production encryption keys. If you want real data, use the production binary instead.

## 📖 Usage Guide

### Apple Documentation Search (live network)

```bash
# Basic search
sosumi docs "SwiftUI layout" --limit 5

# Intent-based search (recommended for agents)
sosumi docs "how to animate" --intent example      # Show code examples
sosumi docs "explain animations" --intent explain  # Get explanations
sosumi docs "animation API" --intent reference     # API reference
sosumi docs "learn animations" --intent learn      # Learning content
sosumi docs "SwiftUI" --intent all                 # All content types

# Fetch specific pages
sosumi doc swiftui/view
sosumi doc "https://developer.apple.com/documentation/groupactivities/adding-spatial-persona-support-to-an-activity"
sosumi doc "doc://design/human-interface-guidelines/shareplay"
```

### Fetch Specific Documentation Pages

```bash
# Markdown output (default)
sosumi doc swiftui/view

# JSON for tooling or agents
sosumi doc groupactivities/drawing_content_in_a_group_session --format json

# Save to disk
sosumi doc swiftui/app --format markdown --output ~/Desktop/swiftui-app.md
```

### WWDC Content (local encrypted DB)

```bash
# Default (user mode, compact summaries)
sosumi wwdc "visionOS layout"

# Agent mode (full transcript blocks)
sosumi wwdc "SwiftUI data flow" --verbosity full

# JSON output for automations
sosumi wwdc "SharePlay" --format json

# Limit to top N hits
sosumi wwdc "SwiftUI" --limit 5
```

### Session / Year / Stats Helpers

```bash
# Fetch by canonical ID
sosumi session wwdc2024-10102 --mode agent --format markdown

# Browse an entire year
sosumi year 2025 --format json

# Inspect the bundle / transcript counts
sosumi stats
```

### Custom Bundle / Offline Modes

```bash
# Point at a custom encrypted bundle (e.g., staging build)
sosumi wwdc "SwiftUI" --bundle /path/to/wwdc_bundle.encrypted
```

## 📚 Documentation Coverage

**Apple Developer Documentation (live):**
- ✅ Swift, SwiftUI, UIKit, AppKit, Combine, RealityKit, SharePlay APIs
- ✅ JSON + Markdown renders (code listings, availability tables)
- ✅ Framework index flattening with deduplication
- ✅ Works from dev builds (requires network)

**WWDC Sessions (local bundle):**
- ✅ 3,216 sessions (2014-2025) with metadata
- ✅ 1,355 full transcripts (2018-2025) and word counts
- ✅ FTS5 SQLite database (~166 MB uncompressed)
- ✅ Encrypted production bundle (~850 MB) w/ AES-256-GCM
- ✅ Dual renderers (user vs agent) + Markdown/JSON output

**Search Features:**
- ✅ SQLite FTS5 full-text search (WWDC)
- ✅ BM25 + topic/metadata boosting
- ✅ Apple documentation “docs” search with optional result limits
- ✅ `doc` endpoint fetch for precise path retrieval
- ✅ <50 ms WWDC queries (local) + live doc fetch with caching

## 🔄 Integration with smith-skill

sosumi-skill is designed to work seamlessly with smith-skill:

```
Architecture question  → smith-skill
API/documentation     → sosumi-skill
Both needed           → Combined response (optimal)
```

**Performance:** Combined use provides intelligent task routing and comprehensive Swift ecosystem guidance.

## 🤝 Integration with Smith Tools

sosumi integrates with the complete Smith Tools ecosystem:

```
~/.claude/skills/
├── smith/           ← Architecture patterns, TCA guidance
└── sosumi/          ← Apple documentation, WWDC reference
```

## 📊 Performance

- **Build size:** ~1.8 MB binary + 850 MB encrypted WWDC bundle
- **WWDC search:** <50 ms (local SQLite FTS5)
- **Apple docs search:** 500‑2000 ms (network), limit via `--limit`/`--type`
- **Coverage:** WWDC 2014‑2025 (3,216 sessions / 1,355 transcripts)
- **Data size:** 166 MB SQLite (unencrypted) / 850 MB encrypted bundle
- **Encryption:** AES-256-GCM for secure distribution

## 🛠️ Development

### Building from Source

```bash
# Clone and build
git clone https://github.com/Smith-Tools/sosumi.git
cd sosumi
swift build -c release
```

### Project Structure

```
sosumi/
├── Package.swift         ← Swift package definition
├── Sources/
│   ├── SosumiDocs/       ← Live Apple documentation client & renderer
│   ├── SosumiWWDC/       ← SQLite DB, bundle manager, WWDC search engine
│   ├── SosumiCLI/        ← CLI entry point (ArgumentParser)
│   └── Skill/            ← Claude skill manifest/instructions
├── Scripts/              ← Build and utility scripts
│   ├── check-security.swift      ← Security validation
│   ├── compress-data.swift       ← Data compression
│   ├── examine-data.swift        ← Data examination
│   ├── secure-obfuscate.swift    ← Data obfuscation
│   └── hybrid-obfuscate.swift    ← Hybrid obfuscation
├── docs/                 ← Documentation
│   ├── KEY_MANAGEMENT.md        ← Encryption and build key documentation
│   ├── INSTALLATION.md           ← Installation guide
│   └── TESTING_*.md              ← Testing documentation
├── Tests/               ← Test suites
└── Resources/
    └── DATA/
        └── wwdc_bundle.encrypted    ← Encrypted database bundle
```

### Data Pipeline (sosumi-data-obfuscation)

```
sosumi-data-obfuscation/
├── Scripts/
│   ├── 1_fetch_metadata.swift      ← Download WWDC session metadata
│   ├── 2_download_transcripts.swift ← Download all transcripts
│   ├── 3_build_database.swift      ← Create SQLite database
│   ├── 4_generate_markdown.swift   ← Format content for agents
│   └── 5_encrypt_bundle.swift      ← Encrypt & bundle everything
├── Outputs/
│   └── wwdc_bundle.encrypted        ← Final encrypted bundle (850MB)
└── SourceData/                        ← Raw downloaded data (not committed)
```

## 📋 Requirements

- **macOS 13.0+** (Ventura)
- **Claude Code** (for skill usage) - optional
- **200 KB disk space**

## 🔗 Related Components

- **[smith-skill](../smith/)** - Architecture validation and TCA guidance
- **[Smith Tools](https://github.com/Smith-Tools/)** - Complete ecosystem

## 🔐 Security & Encryption

sosumi uses AES-256-GCM encryption to protect WWDC transcript data. For detailed information on key management, see [KEY_MANAGEMENT.md](KEY_MANAGEMENT.md).

**Key Points:**
- Production encryption keys are embedded in release binaries only
- Keys are never stored in source code
- Development builds use placeholder keys with mock data
- Each release gets a unique encryption key via GitHub Secrets

## 🤝 Contributing

Contributions welcome! Please:

1. Build and test locally
2. Run: `swift test`
3. Submit PR with clear description
4. Note: Development builds will use mock data - this is expected

For questions:
- GitHub Issues: Feature requests, bug reports
- SECURITY.md: Security-related concerns
- CONTRIBUTING.md: Development guidelines

## 📄 License

MIT - See [LICENSE](LICENSE) for details

---

**sosumi v1.2.0** – Apple Documentation + WWDC Search

Production-ready dual-mode tooling for real-time Apple docs and local WWDC transcripts.

**🔑 User Tip:** Cloned builds use mock WWDC data; download the production binary for the encrypted bundle. Apple documentation search works in both scenarios (requires network).

*Last updated: November 19, 2025*  
*WWDC Coverage: 2014‑2025 (3,216 sessions, 1,355 transcripts)*  
*Features: Live doc search/fetch, SQLite FTS5 DB, AES-256-GCM bundle, User/Agent modes, Markdown/JSON output*
