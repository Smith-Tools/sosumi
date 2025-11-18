# sosumi Installation Guide

Welcome! This guide explains how to install sosumi correctly based on what you're trying to do.

## Table of Contents

- [I just want to use sosumi (recommended)](#i-just-want-to-use-sosumi)
- [I want to use it in Claude Code](#i-want-to-use-it-in-claude-code)
- [I want to contribute or develop features](#i-want-to-contribute-or-develop-features)
- [Troubleshooting](#troubleshooting)

---

## I just want to use sosumi

**This is the recommended approach if you're not contributing to the project.**

### Step 1: Download the binary

Go to the [sosumi releases page](https://github.com/Smith-Tools/sosumi/releases) and download the latest `sosumi-macos` binary.

```bash
# Example (check releases page for latest version)
wget https://github.com/Smith-Tools/sosumi/releases/download/v1.1.0/sosumi-macos

# Or manually download from the releases page
```

### Step 2: Make it executable and install

```bash
# Make executable
chmod +x sosumi-macos

# Option A: Use from current directory
./sosumi-macos wwdc "async await"

# Option B: Install to /usr/local/bin (easier to use anywhere)
sudo mv sosumi-macos /usr/local/bin/sosumi
sosumi wwdc "async await"
```

### Step 3: Start using it

```bash
# Search WWDC sessions
sosumi wwdc "SwiftUI"
sosumi wwdc "async await"
sosumi wwdc "RealityKit"

# See available commands
sosumi --help
```

**That's it!** No configuration needed. Everything works out of the box.

### What if WWDC search doesn't work?

If you get errors like `❌ REAL DATA FAILED` or see mock/fake results:

1. **Verify you downloaded the binary** - Make sure you're using `sosumi-macos` from releases, not a build from source
2. **Check the file size** - Production binary should be ~5MB. If it's <1MB, you may have the wrong file
3. **Verify it's executable** - Run `ls -la sosumi-macos` and check if it has `x` permission
4. **Try again** - Sometimes first use needs to decompress cached data

If still stuck, see [Troubleshooting](#troubleshooting).

---

## I want to use it in Claude Code

Claude Code has built-in skill support. You can use sosumi as a skill without installation.

### Quick Setup

1. Download the production binary from [releases](https://github.com/Smith-Tools/sosumi/releases)
2. Make it available:

```bash
# Option A: Symlink from your current directory
mkdir -p ~/.claude/skills
ln -s $(pwd) ~/.claude/skills/sosumi

# Option B: Copy the binary to the skill directory
mkdir -p ~/.claude/skills/sosumi
cp sosumi-macos ~/.claude/skills/sosumi/sosumi
```

### Usage in Claude Code

```
/skill sosumi wwdc "async await"
/skill sosumi wwdc "RealityKit"
/skill sosumi search "Combine"
```

### Verify Installation

```bash
# Check skill is accessible
ls ~/.claude/skills/sosumi/SKILL.md
```

---

## I want to contribute or develop features

If you're working on sosumi code itself, you'll clone the repository and build from source.

**Important**: Development builds use **fake/mock data** intentionally. This is normal and expected. You cannot get real WWDC data in a development build because production encryption keys are not in the source code (for security reasons).

### Step 1: Clone the repository

```bash
git clone https://github.com/Smith-Tools/sosumi.git
cd sosumi
```

### Step 2: Build

```bash
# Standard debug build
swift build

# Or production build (for testing)
swift build -c release
```

### Step 3: Run tests

```bash
swift test
```

### Step 4: Run locally

```bash
# Use debug build
./.build/debug/sosumi wwdc "SwiftUI"

# Or production build
./.build/release/sosumi wwdc "SwiftUI"
```

### What's This Mock Data?

When you run `sosumi wwdc "SwiftUI"` in a development build, it returns **fake/placeholder results**. This is intentional because:

- ✅ Allows developers to work on features without access to production keys
- ✅ Enables testing and feature development
- ✅ Keeps security keys out of source code
- ⚠️ But means REAL WWDC search doesn't work in development builds

**This is expected behavior.** If you want real WWDC data, use the production binary instead.

### Development Key Setup (Optional)

If you want to test encryption/decryption in development:

```bash
# Set a development key (can be anything, just needs to be 32 bytes)
export SOSUMI_DEV_KEY="test_key_that_is_exactly_32bytes!"

# Then build and test
swift build
swift test
```

See [KEY_MANAGEMENT.md](KEY_MANAGEMENT.md) for detailed information about encryption keys.

---

## Troubleshooting

### Issue: "REAL DATA FAILED" or "Data file not found"

**If you're a user** (downloaded binary):
- This shouldn't happen. Make sure you downloaded from releases, not cloned source
- Try downloading the binary again from [releases page](https://github.com/Smith-Tools/sosumi/releases)
- Verify file size is ~5MB (production binary)

**If you're a developer** (cloned source):
- This is expected in development builds! Mock data is used intentionally
- WWDC search will return placeholder results
- This is normal behavior for development builds

### Issue: "Permission denied" when running sosumi

```bash
# Make sure the binary has execute permission
chmod +x sosumi-macos

# Then try again
./sosumi-macos wwdc "SwiftUI"
```

### Issue: WWDC search returns only a few results or mock data

**In a production binary:**
- Check internet connection
- Try a different search term
- Restart the tool

**In a development build:**
- This is expected! Development builds use mock data by design
- Use the production binary if you want real WWDC data
- See [I want to contribute](#i-want-to-contribute-or-develop-features) section

### Issue: Command not found after installation

If you moved sosumi to `/usr/local/bin/sosumi` but get "command not found":

```bash
# Check if it's actually there
ls -la /usr/local/bin/sosumi

# Check if /usr/local/bin is in your PATH
echo $PATH

# If not, either:
# A) Add to your shell config (~/.zshrc, ~/.bashrc)
#    export PATH="/usr/local/bin:$PATH"
# B) Use the full path
#    /usr/local/bin/sosumi wwdc "SwiftUI"
# C) Reinstall to a directory that's already in PATH
```

### Issue: "Cannot find module SosumiCore" when building

```bash
# Make sure you're in the sosumi directory
cd sosumi

# Clean and rebuild
swift build clean
swift build

# If still broken, check you cloned the full repo
git status
```

### Issue: Skill not found in Claude Code

```bash
# Verify skill is installed correctly
ls ~/.claude/skills/sosumi/SKILL.md

# Should show:
# /Users/your-username/.claude/skills/sosumi/SKILL.md

# If not found, reinstall:
git clone https://github.com/Smith-Tools/sosumi.git
ln -s $(pwd)/sosumi ~/.claude/skills/sosumi
```

---

## Still Having Issues?

1. **Check the [KEY_MANAGEMENT.md](KEY_MANAGEMENT.md)** for technical details about encryption
2. **Read [CONTRIBUTING.md](CONTRIBUTING.md)** for development guidelines
3. **File an issue** on [GitHub Issues](https://github.com/Smith-Tools/sosumi/issues) with:
   - What you're trying to do (user vs developer)
   - Where you got sosumi (releases vs cloned)
   - The exact error message
   - What you've already tried

---

## Quick Summary

| Goal | Do This |
|------|---------|
| Use WWDC search | Download binary from releases |
| Use in Claude Code | Download binary, symlink to ~/.claude/skills |
| Contribute code | Clone repo, build with `swift build` |
| Work on encryption | Read KEY_MANAGEMENT.md, set `SOSUMI_DEV_KEY` env var |
| Real WWDC data | Use binary from releases (not source) |

The key thing to remember: **Development builds use fake data. Real data is in the production binary only.**

