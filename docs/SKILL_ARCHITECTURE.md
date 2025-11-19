# Sosumi Skill Installation Architecture

## Overview

The sosumi skill should be the **result of a build process**, not a copy of the source repository. It consists of three essential components:

### 1. **Compiled Binaries** (from Sources/)
- `sosumi` - Main CLI binary with database integration
- Built from `Sources/SosumiCore/` and `Sources/SosumiCLI/`
- Contains all database search, decryption, and formatting logic
- **Result:** Single executable file (~3.3MB)

### 2. **Skill Structure** (metadata + documentation)
- `skill.json` - Skill manifest with description, allowed tools, version
- `SKILL.md` - Detailed skill documentation (optional but recommended)
- Usage examples, trigger patterns, API descriptions
- **Result:** Small JSON/markdown files (~10KB total)

### 3. **Database Component** (WWDC data)
- **Plain database:** `~/.sosumi/wwdc.db` (local development)
- **Or encrypted bundle:** `wwdc_bundle.encrypted` (production releases)
- 30MB SQLite with 3,215 sessions + 1,355 transcripts + FTS5 index
- **Location:** User home directory, NEVER in skill directory or repos

## Build Process

```
git clone https://github.com/elkraneo/sosumi
cd sosumi

# 1. Build binaries
swift build
# → .build/debug/sosumi

# 2. Prepare skill directory
mkdir -p ~/.claude/skills/sosumi

# 3. Install components
cp .build/debug/sosumi ~/.claude/skills/sosumi/
cp Sources/Skill/skill.json ~/.claude/skills/sosumi/
cp Sources/Skill/SKILL.md ~/.claude/skills/sosumi/

# 4. Database setup (separate)
make -C ../sosumi-data-obfuscation database
cp ../sosumi-data-obfuscation/Outputs/wwdc.db ~/.sosumi/

# Result: Clean skill installation
~/.claude/skills/sosumi/
├── sosumi              # Compiled binary (3.3MB)
├── skill.json          # Skill manifest
└── SKILL.md           # Documentation (optional)

~/.sosumi/wwdc.db      # Database (30MB, separate location)
```

## What Should NOT Be in Skill Directory

❌ **Source code** (`Sources/`, `Package.swift`, etc.)
❌ **Build artifacts** (`.build/`, `*.dSYM/`)
❌ **Development files** (`.git/`, `README.md`, `Makefile`)
❌ **Database files** (`wwdc.db`, `*.encrypted`)
❌ **Development tools** (Scripts/, docs/, Tests/)

## Correct Skill Structure

```
~/.claude/skills/sosumi/
├── sosumi              # Compiled binary only
├── skill.json          # Skill manifest
└── (optional) SKILL.md # Documentation
```

**Total size:** ~3.5MB (vs 200MB+ for full repository)

## Security Architecture

1. **Source Repository:** Contains source code, build scripts, development database
2. **Compiled Binary:** Contains all application logic, no source code
3. **Database:** Separately located in user home directory, can be plain (local) or encrypted (releases)
4. **Skill Directory:** Only production-ready components

## Benefits

✅ **Minimal installation** - Only necessary files
✅ **Security** - No source code or keys in skill directory
✅ **Clean separation** - Database managed separately from binary
✅ **Version control** - Source code stays in repository, not in skill
✅ **Fast deployment** - Small transfer size, quick installation

## Database Distribution Strategy

### Development (Local)
- Plain database: `~/.sosumi/wwdc.db`
- Direct file access, no encryption overhead
- Developers build database locally with `make database`

### Production (Releases)
- Encrypted bundle distributed with releases
- Binary decrypts bundle on first run
- Database still stored in `~/.sosumi/` (plain after decryption)
- Prevents direct database distribution while maintaining functionality

This architecture ensures clean separation between development (source code) and deployment (compiled binary + database) while maintaining security and performance.