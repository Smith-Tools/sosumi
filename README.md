# sosumi - Complete WWDC Transcript Search System

> **Complete WWDC transcript search system for users and AI agents.**

Production-ready WWDC search system with dual output modes: user-friendly snippets with Apple links, and full transcripts for AI synthesis. Features SQLite database, AES-256-GCM encryption, and multiple output formats.

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
- ✅ Works instantly - no configuration needed
- ✅ Data is encrypted and embedded in binary
- 🎯 **This is what you want if you're a user**

**Development Build** (cloned from source):
- ⚠️ Uses **fake/mock data** for testing
- ⚠️ WWDC search returns placeholder results
- ⚠️ Cannot decrypt real encrypted data without production key
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
- **3,000+ WWDC sessions** (2007-2024)
- **Full-text searchable** SQLite database
- **Encrypted data bundle** (~850MB embedded)
- **Real transcripts** with speaker attribution

## 🚀 Quick Start

### For Users: Download Production Binary

```bash
# Go to releases page
# https://github.com/Smith-Tools/sosumi/releases

# Download the latest sosumi-macos binary
# Make it executable and use
chmod +x sosumi-macos

# Test it works - User Mode (default)
./sosumi-macos wwdc-command "SwiftUI"

# Test it works - Agent Mode
./sosumi-macos wwdc-command "SwiftUI" --mode agent

# Test JSON output
./sosumi-macos wwdc-command "SharePlay" --format json
```

**That's it. No configuration needed. Everything works.**

### For Claude Code Users

```bash
# Download production binary from releases
# Create skill directory
mkdir -p ~/.claude/skills/sosumi

# Copy skill manifest (or symlink repo)
# Usage:
/skill sosumi wwdc "SwiftUI"
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

# ⚠️ WWDC search will return mock data - this is expected in development
./.build/debug/sosumi wwdc "async await"
```

**Note**: Development builds use fake data intentionally. This allows developers to work on features without access to production encryption keys. If you want real data, use the production binary instead.

## 📖 Usage Guide

### Basic Search

```bash
# Search in user mode (default) - quick snippets + Apple links
sosumi wwdc-command "SwiftUI animations"

# Search in agent mode - full transcript + metadata
sosumi wwdc-command "SwiftUI animations" --mode agent

# JSON output for programmatic use
sosumi wwdc-command "SharePlay" --format json

# Combine agent mode with JSON output
sosumi wwdc-command "async await" --mode agent --format json
```

### Advanced Commands

```bash
# Get a specific session by ID
sosumi wwdc-session-command "wwdc2024-10102"

# Get session in agent mode with full transcript
sosumi wwdc-session-command "wwdc2024-10102" --mode agent

# List sessions by year
sosumi wwdc-year-command 2024

# Get sessions by year in JSON format
sosumi wwdc-year-command 2023 --format json

# View database statistics
sosumi wwdc-stats-command
```

### Output Modes

**User Mode (default):**
```bash
sosumi wwdc-command "SwiftUI"
# Output: Quick summary + 📍 Full video: https://...
```

**Agent Mode:**
```bash
sosumi wwdc-command "SwiftUI" --mode agent
# Output: Full transcript with metadata for AI synthesis
```

### Output Formats

**Markdown (default):**
```bash
sosumi wwdc-command "SharePlay" --format markdown
# Output: Human-readable formatted results
```

**JSON:**
```bash
sosumi wwdc-command "SharePlay" --format json
# Output: Structured data for API usage
```

### Limiting Results

```bash
# Get top 5 results
sosumi wwdc-command "SwiftUI" --limit 5

# Default limit is 20 results
sosumi wwdc-command "SwiftUI"
```

### Using Custom Bundle

```bash
# Use specific encrypted bundle
sosumi wwdc-command "SwiftUI" --bundle /path/to/wwdc_bundle.encrypted
```

## 📚 Documentation Coverage

**WWDC Sessions:**
- ✅ 3,000+ sessions (2007-2024)
- ✅ Full-text searchable SQLite database
- ✅ Encrypted data bundle (~850MB)
- ✅ Session metadata and speaker info
- ✅ Dual output modes for users and agents

**Search Features:**
- ✅ SQLite FTS5 full-text search
- ✅ Multi-factor relevance scoring
- ✅ BM25 ranking algorithm
- ✅ Natural language queries
- ✅ Fast <50ms search performance

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

- **Build size:** ~1.8 MB (includes 850MB encrypted bundle)
- **Search speed:** <50ms (local SQLite database)
- **Database queries:** Full-text FTS5 with BM25 ranking
- **WWDC coverage:** 2007-2024 (3,000+ sessions)
- **Data size:** 850MB compressed, 3GB+ uncompressed
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
├── SKILL.md              ← Skill manifest and usage guide
├── KEY_MANAGEMENT.md     ← Encryption and build key documentation
├── Package.swift         ← Swift package definition
├── Sources/
│   ├── SosumiCore/
│   │   ├── WWDCDatabase.swift      ← SQLite database & decryption
│   │   ├── MarkdownFormatter.swift ← User/agent output formatting
│   │   ├── WWDCSearch.swift        ← Search engine & legacy support
│   │   └── SosumiCore.swift        ← Core functionality
│   └── SosumiCLI/
│       └── main.swift              ← CLI with --mode and --format flags
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

**sosumi v1.1.0** - Complete WWDC Transcript Search System

Production-ready dual-mode WWDC search for users and AI agents.

**🔑 User Tip:** If WWDC search isn't working after cloning from source, you're using a development build with mock data. Download the production binary instead: [Releases](https://github.com/Smith-Tools/sosumi/releases)

*Last updated: November 18, 2025*
*WWDC Coverage: 2007-2024 (3,000+ sessions)*
*Features: SQLite database, AES-256-GCM encryption, User/Agent modes, JSON/Markdown output*
