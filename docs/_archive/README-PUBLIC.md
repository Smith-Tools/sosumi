# sosumi - Apple Documentation & WWDC Skill

**A hybrid Claude Code skill + CLI tool for comprehensive Apple developer documentation access.**

## 🎯 What is sosumi?

sosumi provides instant access to Apple's developer ecosystem through two integrated components:

1. **Claude Skill** - `/skill sosumi` for intelligent documentation queries
2. **CLI Tool** - `sosumi` for command-line documentation access

Both components share optimized data and caching for maximum performance.

## 🚀 Quick Start

### **Installation**
```bash
# Install via Homebrew (recommended)
brew install Smith-Tools/homebrew-smith/sosumi

# Or install manually
git clone https://github.com/Smith-Tools/sosumi.git
cd sosumi
make install
```

### **Usage Examples**
```bash
# Claude skill (context-aware, intelligent routing)
/skill sosumi search "SwiftUI animations"
/skill sosumi wwdc "Combine framework"
/skill sosumi shareplay

# CLI tool (scripting, automation, JSON output)
sosumi search "SwiftUI animations"
sosumi search "Combine" --format json
sosumi performance --verbose
```

## ✨ Features

### **Claude Skill**
- 🧠 **Smart Search** - Context-aware result ranking
- 📚 **Apple Documentation** - Swift, SwiftUI, Combine, frameworks
- 🎥 **WWDC Integration** - Full session transcripts
- ⚡ **Performance Optimized** - Intelligent caching system
- 🔍 **Specialized Searches** - SharePlay, visionOS, async/await

### **CLI Tool**
- 🔧 **Command-line Interface** - Scripting and automation
- 📄 **JSON Output** - Machine-readable results
- ⚡ **Batch Processing** - Handle multiple queries
- 📊 **Performance Monitoring** - Cache statistics and metrics
- 🔄 **Cache Management** - Fine-grained control

## 📦 What Gets Installed

```bash
/usr/local/bin/sosumi                              ← CLI tool
~/.claude/skills/sosumi.md                         ← Claude skill
/usr/local/share/sosumi/Resources/                 → Optimized data
```

## 🔧 Development

### **Building from Source**
```bash
git clone https://github.com/Smith-Tools/sosumi.git
cd sosumi
swift build -c release
```

### **Project Structure**
```
sosumi/
├── SKILL.md              ← Claude skill manifest
├── Package.swift          ← Swift package definition
├── Sources/
│   ├── SosumiCLI/         ← CLI tool implementation
│   └── SosumiCore/        ← Core library
├── Resources/             ← Optimized data packages
│   └── DATA/
│       └── wwdc_sessions_*.compressed
├── Scripts/               ← Build and utility scripts
└── Tests/                 ← Test suites
```

## ⚡ Performance

- **Search**: 1-50ms (cached content)
- **API Search**: 500-2000ms (live content)
- **Memory Usage**: ~50MB for full index
- **Cache Hit Rate**: 60-80% for typical usage
- **Compression**: 70-90% size reduction

## 🔄 Integration with Smith Tools

sosumi integrates seamlessly with the Smith Tools ecosystem:

```bash
~/.claude/skills/
├── smith/           ← Architecture patterns, TCA guidance
└── sosumi/          ← Apple documentation, API reference
```

**Workflow:**
- **Architecture patterns** → smith skill
- **API documentation** → sosumi (skill or CLI)
- **Complete solutions** → Use both components

## 📋 Requirements

- **macOS 13.0+** (Ventura)
- **Swift 5.7+** (for building from source)
- **Claude Code** (for skill usage)
- **2GB disk space** for cached documentation

## 🆙 Updates

```bash
# Update via Homebrew
brew upgrade sosumi

# Update skill data
/skill sosumi update --force

# Update CLI cache
sosumi cache refresh
```

## 🤝 Contributing

Contributions welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### **Areas for Contribution**
- UI/UX improvements
- Performance optimizations
- New search features
- Documentation improvements
- Integration examples

## 📄 License

[License information]

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/Smith-Tools/sosumi/issues)
- **Discussions**: [GitHub Discussions](https://github.com/Smith-Tools/sosumi/discussions)
- **Documentation**: [Smith Tools Docs](https://smith-tools.github.io/)

---

**sosumi** is part of the [Smith Tools](https://github.com/Smith-Tools) ecosystem for modern Swift development.

*Last updated: [Date]*
*Version: [Version]*