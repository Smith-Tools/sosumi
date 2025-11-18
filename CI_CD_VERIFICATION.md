# CI/CD Verification Guide

**For:** Verifying GitHub Actions workflows use SOSUMI_ENCRYPTION_KEY correctly
**Status:** Ready for production deployment

---

## 🔐 GitHub Secrets Setup (Already Done)

The `SOSUMI_ENCRYPTION_KEY` is already configured as a GitHub Secret.

### Verify Secret Exists

1. Go to: `https://github.com/your-org/sosumi/settings/secrets/actions`
2. Look for: `SOSUMI_ENCRYPTION_KEY`
3. Status should show: ✅ Set

### Secret Details

```
Name: SOSUMI_ENCRYPTION_KEY
Value: (32-byte base64-encoded AES-256 key)
Type: Repository Secret
Visibility: Private (only used in Actions)
```

---

## ✅ CI/CD Workflow Verification

### Trigger Test Build

Push a test commit to verify CI/CD:

```bash
cd /Volumes/Plutonian/_Developer/Smith\ Tools/sosumi

# Make a trivial change
echo "# Test: $(date)" >> TESTING_GUIDE.md

# Commit and push
git add TESTING_GUIDE.md
git commit -m "test: verify CI/CD with encryption key"
git push origin main
```

### Monitor GitHub Actions

1. Go to: `https://github.com/your-org/sosumi/actions`
2. Find your commit in the workflow list
3. Click to view details
4. Watch for these steps:

**✅ Expected CI Steps:**
```
[✓] Checkout code
[✓] Setup Swift (6.1.2 or later)
[✓] Cache dependencies
[✓] Build (debug)
[✓] Run tests
[✓] Test with encryption key
[✓] Build release binary
[✓] Create GitHub release
[✓] Upload artifacts
```

**✅ Expected Output Patterns:**
```
Running build...
Build complete! ✓
Running tests...
Test cases compiled: 90+
SOSUMI_ENCRYPTION_KEY detected ✓
Building release binary...
Binary size: ~1-2 MB
Release artifact uploaded ✓
```

---

## 🔧 How Encryption Key is Used

### In Build Process

The GitHub Actions workflow injects the key during the release build:

```yaml
# .github/workflows/release.yml (relevant excerpt)
- name: Build release binary
  env:
    SOSUMI_ENCRYPTION_KEY: ${{ secrets.SOSUMI_ENCRYPTION_KEY }}
  run: |
    swift build -c release \
      -Xswiftc -Xfrontend \
      -Xswiftc -disable-strict-concurrency
```

### In Source Code

The key is accessed via environment variable in `WWDCSearch.swift`:

```swift
#if !DEBUG
  #if SOSUMI_ENCRYPTION_KEY
    let prodKey = "\(SOSUMI_ENCRYPTION_KEY)"
    guard prodKey.count == 32 else {
        fatalError("❌ SOSUMI_ENCRYPTION_KEY must be exactly 32 bytes")
    }
    return SymmetricKey(data: Data(prodKey.utf8))
  #else
    fatalError("❌ SOSUMI_ENCRYPTION_KEY not provided")
  #endif
#endif
```

**Key Safety:**
- ✅ Never logged in build output
- ✅ Only available in release builds
- ✅ Development builds use placeholder
- ✅ Encrypted in transit
- ✅ Never committed to git

---

## 📋 Pre-Release Checklist

Before cutting a production release:

```bash
# 1. Verify local build with key
export SOSUMI_ENCRYPTION_KEY="<32-byte-key-from-secret>"
swift build -c release

# 2. Verify binary works
.build/release/sosumi --version
# Should show: sosumi 1.1.0

# 3. Verify bundle is deployed
ls -lh Resources/DATA/wwdc_bundle.encrypted
# Should be ~850 MB

# 4. Run quick test
.build/release/sosumi wwdc "test" --mode user 2>/dev/null | head -5
# Should show results with Apple links

# 5. Check git status
git status
# Should be clean (no uncommitted changes)

# 6. Push and trigger CI
git push origin main
```

---

## 🚀 Release Process

### Manual Release (if needed)

```bash
cd /Volumes/Plutonian/_Developer/Smith\ Tools/sosumi

# Create version tag
git tag -a v1.1.1 -m "Release v1.1.1 - WWDC transcript search system"

# Push tag (triggers release workflow)
git push origin v1.1.1
```

### Automated Release via GitHub Actions

1. Push tag from local: `git push origin v1.1.1`
2. GitHub Actions automatically:
   - ✅ Builds with encryption key
   - ✅ Creates GitHub Release
   - ✅ Uploads release artifact
   - ✅ Generates release notes

### Verify Release

After GitHub Actions completes:

```bash
# Check released binary
gh release download v1.1.1 -p "sosumi"

# Verify it works
./sosumi --version
# Should show: sosumi 1.1.1

# Check bundle is included
./sosumi wwdc "SwiftUI" --mode user 2>/dev/null | head -3
# Should return results
```

---

## 🧪 Test Scenarios

### Scenario 1: Build Without Key (Debug)

```bash
# Local development build (key not needed)
swift build

# Expected: ✅ Succeeds with placeholder key warning
# Impact: WWDC search won't work but CLI structure is fine
```

### Scenario 2: Build With Key (Release)

```bash
export SOSUMI_ENCRYPTION_KEY="<actual-key>"
swift build -c release

# Expected: ✅ Succeeds silently (key is embedded)
# Impact: Full WWDC search functionality available
```

### Scenario 3: CI/CD with GitHub Secret

```bash
# Push code to GitHub
git push origin main

# GitHub Actions automatically:
# ✅ Gets SOSUMI_ENCRYPTION_KEY from secrets
# ✅ Builds release binary with key embedded
# ✅ Uploads binary to releases
# Impact: Binary available for download with WWDC search working
```

---

## 🔍 Troubleshooting CI/CD

### Workflow Shows "Key Not Available"

**Symptom:** Build fails with message about missing `SOSUMI_ENCRYPTION_KEY`

**Cause:** Secret not passed to workflow environment

**Fix:**
```yaml
# Ensure env section includes:
env:
  SOSUMI_ENCRYPTION_KEY: ${{ secrets.SOSUMI_ENCRYPTION_KEY }}
```

### Binary Size is Smaller Than Expected

**Symptom:** Release binary is <500 KB (should be 1-2 MB)

**Cause:** Bundle not embedded or optimization removed it

**Fix:**
```bash
# Verify bundle exists:
ls -lh Resources/DATA/wwdc_bundle.encrypted

# Check if it's included in binary:
strings .build/release/sosumi | grep -i "wwdc" | head -3
```

### Release Artifact Not Uploaded

**Symptom:** GitHub Release page has no downloads

**Cause:** Upload step failed

**Fix:** Check workflow logs for errors:
```bash
gh run view --log <run-id> | grep -i "upload\|error"
```

### Tests Fail in CI but Pass Locally

**Symptom:** Local `swift test` passes, CI fails

**Cause:** Environment differences (key not injected for test step)

**Fix:** Ensure test step doesn't require encryption key:
```yaml
# Tests should work without key (use mock data)
# Only release build needs the key
```

---

## 📊 Monitoring

### Check Latest Build

```bash
# View most recent workflow run
gh run list --limit 1

# View detailed log
gh run view <run-id> --log
```

### Monitor Binary Downloads

```bash
# View release download stats
gh release view v1.1.1

# Check asset downloads (if available)
gh api repos/{owner}/{repo}/releases/assets/{asset-id}
```

---

## 🎯 Success Indicators

All systems working when:

✅ **Local Build:** `swift build -c release` succeeds with key
✅ **CI Build:** GitHub Actions completes all steps
✅ **Test:** `swift test` passes or skips gracefully
✅ **Release:** Binary uploaded and available
✅ **Functionality:** Downloaded binary searches WWDC content
✅ **Security:** Key never appears in logs or artifacts
✅ **Performance:** Build completes in <5 minutes

---

## 🔐 Security Checklist

Before production release:

```bash
# ✅ Verify key is NOT in version control
git log --all --oneline -S "SOSUMI_ENCRYPTION_KEY=" | head -1
# Should show no results

# ✅ Verify key is NOT in build output
gh run view <run-id> --log | grep -i "SOSUMI_ENCRYPTION_KEY"
# Should show no results

# ✅ Verify GitHub Secret is set to Private
# Go to: Settings > Secrets > SOSUMI_ENCRYPTION_KEY
# Status should show: "Private"

# ✅ Verify releases are code-signed (if enabled)
gh release view v1.1.1 --json assets
# Check for signature files
```

---

## 📝 Release Notes Template

When creating a release, include:

```markdown
# sosumi v1.1.1 - WWDC Transcript Search System

## Features

- 🔍 Search 3,215+ WWDC sessions (2007-2024)
- 📖 Full transcripts for AI agents
- 🔐 AES-256-GCM encrypted bundle
- 🎯 Dual-mode search (user snippet + agent full transcript)
- 📦 Embedded database (~850 MB compressed)

## What's New

- ✅ Complete data pipeline with 5 scripts
- ✅ Concurrent transcript downloading
- ✅ Full-text search with relevance ranking
- ✅ Apple attribution in all outputs
- ✅ 90+ unit tests

## Installation

Download the binary and use:

```bash
./sosumi search "SwiftUI"
./sosumi wwdc "async await" --mode agent
./sosumi wwdc-stats-command
```

## How to Use

**For Users:**
```bash
sosumi wwdc "your query" --mode user
# Returns: Quick snippet + link to official Apple video
```

**For AI Agents:**
```bash
sosumi wwdc "your query" --mode agent
# Returns: Full transcript in Markdown for synthesis
```

## Security

- Encrypted with AES-256-GCM
- No unencrypted data in repository
- All outputs include Apple attribution
- Built in CI/CD with secure key management

## System Requirements

- Swift 6.1.2 or later
- macOS 12+ / Linux
```

---

## 🆘 Getting Help

If workflows fail:

1. **Check workflow logs:** `gh run view <run-id> --log`
2. **Verify secret exists:** `gh secret list`
3. **Check recent changes:** `git log --oneline -5`
4. **Review error message:** Look for key-related failures
5. **Rebuild locally:** `swift build -c release` with key set

---

**Status:** ✅ CI/CD system is production-ready with secure key management.
**Next:** Monitor first production release to verify everything works end-to-end.
