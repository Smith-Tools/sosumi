# Encryption Key Management for sosumi-skill

**Status**: Production-Ready ✅
**Last Updated**: 2025-11-18
**Audience**: DevOps, Build Engineers, Release Managers

---

## Overview

The sosumi-skill uses AES-256-GCM encryption to protect WWDC session transcripts. This document explains how encryption keys are managed across development, staging, and production environments.

### Key Principle

**Keys are never stored in source code.** Instead, they are injected during the build process and compiled into the final binary.

---

## Usage Scenarios

### Scenario 1: End Users (Downloaded Binary)

Users download pre-compiled binaries from GitHub Releases.

```bash
# Download sosumi binary
wget https://github.com/Smith-Tools/sosumi/releases/download/v1.1.0/sosumi-macos

# Run - works immediately with embedded production key
./sosumi search "SharePlay"
```

**How it works**:
- Binary is built with production key injected at GitHub Actions build time
- Key is compiled into the binary (not extractable)
- Works without any user configuration

**Security**: ✅ Production key is protected inside compiled binary

---

### Scenario 2: Developers (Clone Repository)

Developers clone the repository to work on the codebase.

```bash
# Clone repository
git clone https://github.com/Smith-Tools/sosumi.git

# Build locally
cd sosumi
swift build

# ⚠️ Build with development key
export SOSUMI_DEV_KEY="your_32_byte_dev_key_here_"  # Set before running
swift run sosumi search "SwiftUI"
```

**How it works**:
- Source code contains placeholder keys: `REPLACE_WITH_ACTUAL_DEVELOPMENT_KEY_32_BYTES`
- Developers must provide their own development key via environment variable
- If no key provided, build will warn but still works with test data
- Production key is NOT in source code

**Security**: ✅ Real keys never exposed in source code

---

### Scenario 3: CI/CD Pipeline (GitHub Actions)

The build system injects the production key during release builds.

```yaml
name: Build and Release

on:
  push:
    tags: ['v*']

jobs:
  build:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build with Production Key
        run: |
          swift build -c release \
            -Xswiftc -DSOSUMI_ENCRYPTION_KEY="$SOSUMI_PRODUCTION_KEY"
        env:
          SOSUMI_PRODUCTION_KEY: ${{ secrets.SOSUMI_ENCRYPTION_KEY }}

      - name: Create Release
        uses: softprops/action-gh-release@v1
        with:
          files: .build/release/sosumi
```

**How it works**:
- Production key stored in GitHub Secrets (never visible in logs)
- Key injected at build time via Swift compiler flag
- Binary is compiled with key embedded
- Release artifact is production-ready

**Security**: ✅ Key is injected via CI/CD secrets, never exposed

---

## Key Types and Formats

### Development Key
- **Length**: Must be exactly 32 bytes (for AES-256)
- **Storage**: Environment variable `SOSUMI_DEV_KEY` or provided at build time
- **Format**: Any 32-character string (can be hex, alphanumeric, etc.)
- **Example**: `"your_32_byte_dev_key_here_"`
- **Scope**: Only for local development and testing

**⚠️ Development keys are NOT secret** - they're placeholders to allow the code to compile and run locally.

### Production Key
- **Length**: Must be exactly 32 bytes
- **Storage**: GitHub Secrets as `SOSUMI_ENCRYPTION_KEY`
- **Format**: Cryptographically random 32-byte hex string
- **Generated via**: `openssl rand -hex 16` (generates 32 characters / 16 bytes hex)
- **Scope**: Production binaries only
- **Rotation**: See [Key Rotation](#key-rotation) below

---

## Build Configurations

### Development Build (Local)

```bash
# With environment variable (recommended for development)
export SOSUMI_DEV_KEY="local_development_key_32bytes"
swift build

# Without environment variable (uses placeholder)
swift build  # Prints warning, uses "REPLACE_WITH_ACTUAL_DEVELOPMENT_KEY_32_BYTES"
```

**What happens**:
- Code compiles with DEBUG flag
- Uses environment variable or placeholder
- Mock data loads if real data unavailable
- For testing and feature development only

### Production Build (GitHub Actions)

```bash
# Build command in GitHub Actions CI/CD
swift build -c release \
  -Xswiftc -DSOSUMI_ENCRYPTION_KEY="$SOSUMI_PRODUCTION_KEY"
```

**What happens**:
- Code compiles with RELEASE flag
- Requires production key via compiler flag
- Build fails with clear error if key not provided
- Binary is production-ready and signed

**Build command for local production testing** (if needed):

```bash
# ⚠️ Only for testing - do not do this in production
export SOSUMI_PRODUCTION_KEY="test_key_that_is_32bytes!"
swift build -c release \
  -Xswiftc -DSOSUMI_ENCRYPTION_KEY="$SOSUMI_PRODUCTION_KEY"
```

---

## Installation and Setup

### For End Users

```bash
# Download from releases page
# https://github.com/Smith-Tools/sosumi/releases

# Verify signature (optional but recommended)
# gpg --verify sosumi-macos.sig sosumi-macos

# Make executable and install
chmod +x sosumi-macos
sudo mv sosumi-macos /usr/local/bin/sosumi

# Use immediately
sosumi search "async await"
```

**No configuration needed** - key is already embedded in the binary.

### For Developers

```bash
# 1. Clone repository
git clone https://github.com/Smith-Tools/sosumi.git
cd sosumi

# 2. Set development key (optional)
# If you have a specific development key to use:
export SOSUMI_DEV_KEY="your_development_key_32bytes"

# 3. Build
swift build

# 4. Test
swift test

# 5. Run locally
./.build/debug/sosumi search "SwiftUI"
```

**Environment Variables** (optional):

```bash
# For development testing
export SOSUMI_DEV_KEY="your_32_byte_development_key"

# To test with real production-like setup
export SOSUMI_OBFUSCATION_KEY="test_key_32_bytes_for_search"
```

### For Contributors

Contributors can work on the codebase without access to any real keys:

```bash
# Clone and build
git clone https://github.com/Smith-Tools/sosumi.git
cd sosumi
swift build  # Works with placeholder keys

# Run tests
swift test

# Submit PR
# CI/CD will use real keys to verify your changes
```

---

## Key Generation and Rotation

### Generating a New Production Key

**Requirements**:
- Use cryptographically strong randomness
- Must be exactly 32 bytes (for AES-256)

**Command** (macOS/Linux):

```bash
# Generate random 32-byte key in hex format
NEW_KEY=$(openssl rand -hex 16)
echo "Generated key: $NEW_KEY"
echo "Length: ${#NEW_KEY} characters (32 bytes in hex)"
```

**Output**:
```
Generated key: a3f9b2e1c8d4f7a9e2b5c1d8f4a7e3b9
Length: 32 characters (32 bytes in hex)
```

### Storing Production Key

**In GitHub Secrets**:

```bash
# 1. Go to repository Settings → Secrets and variables → Actions
# 2. Create new secret: SOSUMI_ENCRYPTION_KEY
# 3. Paste the generated key value
# 4. Do NOT include quotes or spaces
```

**Verification**:

```bash
# The CI/CD pipeline will automatically use the secret
# Verify by checking GitHub Actions run output (key value will be masked)
```

### Key Rotation Procedure

When you need to rotate the production key (yearly recommended):

#### Step 1: Generate New Key
```bash
NEW_KEY=$(openssl rand -hex 16)
echo "Store this securely: $NEW_KEY"
```

#### Step 2: Re-encrypt Data
```bash
# In sosumi-data-obfuscation repository
export SOSUMI_OBFUSCATION_KEY="$NEW_KEY"
swift Scripts/obfuscate-data.swift SourceData/wwdc_comprehensive.json Outputs/wwdc_sessions_rotated.json.compressed
```

#### Step 3: Update GitHub Secret
```
1. Go to GitHub Secrets
2. Update SOSUMI_ENCRYPTION_KEY with new value
3. Document rotation date
```

#### Step 4: Deploy New Data
```bash
# Push re-encrypted data to sosumi-skill
cp Outputs/wwdc_sessions_rotated.json.compressed \
   sosumi-skill/Resources/DATA/wwdc_sessions_2024_enhanced.json.compressed

# Create release
git tag v1.1.1
git push --tags
```

#### Step 5: Verify
```bash
# New binary built with new key
# Old binaries still work (but won't update data)
# New releases have new key embedded
```

---

## Security Checklist

### Before Production Release

- [ ] Production key is generated using `openssl rand -hex 16`
- [ ] Key is stored in GitHub Secrets, NOT in code
- [ ] `.gitignore` includes Config/encryption_keys.json
- [ ] Pre-commit hooks are installed and passing
- [ ] CI/CD pipeline correctly injects key via build flag
- [ ] Data is encrypted with the same key
- [ ] Binary is code-signed (optional but recommended)
- [ ] Release notes document key rotation schedule

### For Development

- [ ] Development key is just a placeholder (not secret)
- [ ] No real production keys in environment variables
- [ ] Pre-commit hooks prevent accidental key commits
- [ ] Team members understand not to share keys

### For Operations

- [ ] Key rotation schedule is documented (annual minimum)
- [ ] Key backup procedure exists
- [ ] Incident response plan if key is compromised
- [ ] Audit log shows who accessed the key secret

---

## Troubleshooting

### Error: "SOSUMI_ENCRYPTION_KEY not provided"

**Cause**: Production build without key injection

**Solution**:
```bash
# Local development - use environment variable
export SOSUMI_DEV_KEY="test_key_that_is_32bytes!"
swift build

# CI/CD - add GitHub Secret and update workflow
```

### Error: "Encryption key must be exactly 32 bytes"

**Cause**: Key is wrong length

**Solution**:
```bash
# Check key length
echo -n "$YOUR_KEY" | wc -c

# Should output: 32
# If not, regenerate:
NEW_KEY=$(openssl rand -hex 16)
```

### Data decryption fails

**Cause**: Using wrong key to decrypt data

**Solution**:
1. Verify data was encrypted with the key you're using
2. Check that both encryption and decryption use same key
3. Ensure data files weren't corrupted during transfer

---

## Best Practices

1. **Never commit keys to git**
   ```bash
   # Good
   export SOSUMI_DEV_KEY="placeholder_32_bytes_long"

   # Bad
   git add Config/encryption_keys.json  # ❌ Don't do this
   ```

2. **Use different keys for different environments**
   ```bash
   SOSUMI_DEV_KEY       # For local development (can be public)
   SOSUMI_STAGING_KEY   # For staging (in staging GitHub secret)
   SOSUMI_ENCRYPTION_KEY  # For production (protected)
   ```

3. **Rotate keys regularly** (at least annually)

4. **Audit key usage** via GitHub Actions logs

5. **Backup production key** in secure vault (encrypted)

---

## Related Files

- `Sources/SosumiCore/WWDCSearch.swift` - Key usage in production code
- `.github/workflows/build-and-release.yml` - CI/CD key injection
- `sosumi-data-obfuscation/KEY_MANAGEMENT.md` - Data encryption side

---

## Questions?

For security-related questions:
- Create a private security advisory on GitHub
- Do NOT discuss in public issues

For implementation questions:
- File an issue: https://github.com/Smith-Tools/sosumi/issues
- Reference: `key-management` label

---

**Last Reviewed**: 2025-11-18
**Next Review**: 2026-11-18 (annually)
