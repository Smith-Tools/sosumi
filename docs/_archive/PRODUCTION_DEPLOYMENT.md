# Production Deployment Checklist

**Document Version**: 1.0
**Last Updated**: 2025-11-18
**Status**: Ready for Production Deployment

---

## Pre-Deployment Verification (1 Week Before Release)

### Security Checklist

- [ ] **No hardcoded keys in source code**
  ```bash
  grep -r "12345678" Sources/  # Should return nothing
  grep -r "CHANGE_THIS" Sources/  # Should return nothing
  ```

- [ ] **All placeholder keys are placeholders**
  ```bash
  grep -r "REPLACE_WITH_ACTUAL_" Sources/  # OK - these are placeholders
  ```

- [ ] **Git history is clean**
  ```bash
  git log --all -p -- Sources/ | grep -i "encryption.*key" | grep -v "REPLACE_WITH"
  # Should return nothing
  ```

- [ ] **Pre-commit hooks are configured**
  ```bash
  cat .pre-commit-config.yaml | grep detect-secrets
  # Should show detect-secrets configuration
  ```

- [ ] **.gitignore is correct**
  ```bash
  cat .gitignore | grep -i "encrypt\|secret\|key"
  # Should show security rules
  ```

### Code Verification

- [ ] **Build succeeds in DEBUG mode**
  ```bash
  swift build
  # Should complete successfully
  ```

- [ ] **All tests pass**
  ```bash
  swift test
  # All tests should pass
  ```

- [ ] **No compilation warnings**
  ```bash
  swift build 2>&1 | grep -i "warning"
  # Should return nothing (or only Swift version warnings)
  ```

- [ ] **CLI works with test data**
  ```bash
  ./.build/debug/sosumi search "SharePlay"
  # Should return results
  ```

### Data Verification

- [ ] **Encrypted data file exists**
  ```bash
  ls -lh Resources/DATA/wwdc_sessions_2024_enhanced.json.compressed
  # Should show file size ~18KB
  ```

- [ ] **Data can be decompressed**
  ```bash
  # Test decompression of actual data file
  swift run sosumi test-command
  # Should show successful decompression
  ```

- [ ] **Search index is valid**
  ```bash
  swift run sosumi test-command | grep "search_index"
  # Should confirm valid search index
  ```

---

## Production Key Setup (3 Days Before Release)

### Generate Production Encryption Key

```bash
# Generate new 32-byte key
PROD_KEY=$(openssl rand -hex 16)
echo "Production Key: $PROD_KEY"
echo "Key Length: $(echo -n "$PROD_KEY" | wc -c) bytes"

# MUST output: 32 bytes
# Example output:
# a3f9b2e1c8d4f7a9e2b5c1d8f4a7e3b9
```

**Store this key securely** - you'll need it for GitHub Secrets.

### Configure GitHub Secrets

1. Navigate to: Repository Settings → Secrets and variables → Actions

2. Create new secret:
   - Name: `SOSUMI_ENCRYPTION_KEY`
   - Value: `[paste your production key]`

3. **Verify it was added** (don't show the value, just confirm it exists):
   ```bash
   # GitHub UI will show the secret exists
   # Secret value is masked in logs
   ```

### Data Encryption (sosumi-data-obfuscation)

In the sosumi-data-obfuscation repository:

```bash
# 1. Set the same encryption key
export SOSUMI_OBFUSCATION_KEY="$PROD_KEY"  # Same key as above

# 2. Re-encrypt all data
swift Scripts/obfuscate-data.swift \
  SourceData/wwdc_all_sessions.json \
  Outputs/wwdc_sessions_2024_enhanced.json

# 3. Verify output
ls -lh Outputs/wwdc_sessions_2024_enhanced.json.compressed
# Should show ~9KB compressed file

# 4. Copy to sosumi-skill
cp Outputs/wwdc_sessions_2024_enhanced.json.compressed \
   ../sosumi-skill/Resources/DATA/

# 5. Commit data update
cd ../sosumi-skill
git add Resources/DATA/
git commit -m "Update WWDC data for v1.1.0 release"
```

---

## SPM Distribution Considerations

### Swift Package Manager Support

The sosumi-skill can be distributed via SPM in two ways:

#### Option 1: Binary Target (Recommended)

```swift
// In Package.swift
let package = Package(
    name: "sosumi",
    products: [
        .executable(name: "sosumi", targets: ["SosumiCLI"])
    ],
    targets: [
        .binaryTarget(
            name: "sosumi",
            url: "https://github.com/Smith-Tools/sosumi/releases/download/v1.1.0/sosumi.xcframework.zip",
            checksum: "[sha256-checksum]"
        )
    ]
)
```

**Advantages**:
- ✅ Users get pre-built binary with key embedded
- ✅ No need to build from source
- ✅ Works with SPM: `swift package add Smith-Tools/sosumi`
- ✅ Fastest installation

**Setup Required**:
```bash
# Create XCFramework with embedded key
swift build -c release \
  -Xswiftc -DSOSUMI_ENCRYPTION_KEY="$PROD_KEY"

# Export as XCFramework (requires Xcode tooling)
# Upload to GitHub Releases
```

#### Option 2: Source Distribution (For Contributors)

Current setup - users build from source.

**Disadvantages**:
- ❌ Requires environment variable setup
- ❌ Only works for developers with key
- ❌ Not suitable for end users via SPM

**When to use**:
- Open source contributors
- Team members with access to key
- Development/testing only

### Recommendation for Production

**Use Binary Target for SPM Distribution**:

```bash
# In GitHub Actions, after building:
# 1. Create XCFramework
# 2. Compress it
# 3. Upload to release
# 4. Update Package.swift with URL and checksum
```

This way:
- End users: `swift package add sosumi` → get binary
- Contributors: Clone repo → build from source

---

## Release Day (Day of Deployment)

### Pre-Release Testing

- [ ] **Final build test with real key** (optional, for production verification)
  ```bash
  export SOSUMI_ENCRYPTION_KEY="$PROD_KEY"
  swift build -c release \
    -Xswiftc -DSOSUMI_ENCRYPTION_KEY="$SOSUMI_ENCRYPTION_KEY"
  ```

- [ ] **Test the release binary**
  ```bash
  ./.build/release/sosumi search "SwiftUI"
  # Should return results with decrypted data
  ```

- [ ] **Check version is updated**
  ```bash
  grep "version" Package.swift
  # Should match release tag
  ```

### Create Release

```bash
# 1. Create release tag
git tag -a v1.1.0 -m "Production release with enhanced WWDC search"

# 2. Push tag (triggers GitHub Actions)
git push origin main
git push origin v1.1.0

# 3. Monitor GitHub Actions
# - Wait for build job to complete
# - Verify no errors in logs
# - Check that binary was created
```

### GitHub Actions Workflow

The `.github/workflows/build-and-release.yml` will:

1. ✅ Check out code
2. ✅ Inject production key from `SOSUMI_ENCRYPTION_KEY` secret
3. ✅ Build with `-DSOSUMI_ENCRYPTION_KEY="$SOSUMI_ENCRYPTION_KEY"`
4. ✅ Run tests
5. ✅ Create signed binary
6. ✅ Create GitHub release
7. ✅ Upload binary artifact

**Key injection happens here** - you don't need to do anything.

### Verify Release

```bash
# 1. Check GitHub Releases page
# https://github.com/Smith-Tools/sosumi/releases/v1.1.0

# 2. Download the binary
wget https://github.com/Smith-Tools/sosumi/releases/download/v1.1.0/sosumi-macos

# 3. Test it
chmod +x sosumi-macos
./sosumi-macos search "SharePlay"
# Should return results
```

---

## Post-Release (1 Day After Release)

### Verify Production Binary

- [ ] **Binary works for users**
  - Download from releases page
  - Test locally: `./sosumi search "async"`
  - Should return results

- [ ] **Search works correctly**
  - Test various queries
  - Verify results are relevant
  - Check time segments are present

- [ ] **No errors in production logs**
  - Monitor GitHub Issues
  - Check for user reports of decryption failures
  - Respond to any bugs

### Document Release

- [ ] **Update CHANGELOG**
  ```markdown
  ## v1.1.0 (2025-11-18)
  - Enhanced search with synonym expansion
  - Production key management implemented
  - Security hardening for all environments
  - Support for 8+ WWDC sessions
  ```

- [ ] **Update README**
  - Version number
  - Latest features
  - Installation instructions

- [ ] **Notify users**
  - GitHub Releases page
  - Twitter/X announcement
  - Newsletter (if applicable)

---

## Key Security Properties After Release

### User Perspective

- ✅ Download binary from releases
- ✅ Run immediately without configuration
- ✅ Encryption key is embedded and protected
- ✅ Cannot extract or modify key from binary
- ✅ Works offline after download

### Developer Perspective

- ✅ Source code has no real keys
- ✅ Clone and build requires environment variable
- ✅ Pre-commit hooks prevent accidental key commits
- ✅ CI/CD injects key at build time only
- ✅ Production and development are separate

### Operations Perspective

- ✅ Key rotations documented and automated
- ✅ GitHub Secrets stores production key securely
- ✅ Build logs mask sensitive information
- ✅ Audit trail available in GitHub Actions
- ✅ Incident response plan for key compromise

---

## Rollback Procedure (If Issues)

If decryption fails in production:

### Immediate Actions

```bash
# 1. Stop the release
# GitHub → Releases → v1.1.0 → Delete (or mark as pre-release)

# 2. Investigate
# Check GitHub Actions logs (masked)
# Verify key was injected correctly
# Check data file integrity
```

### Troubleshooting

```bash
# Verify key and data are in sync
# In sosumi-data-obfuscation:
export SOSUMI_OBFUSCATION_KEY="$PROD_KEY"
swift Scripts/search-obfuscated.swift \
  Outputs/wwdc_sessions_2024_enhanced.json.compressed \
  "SwiftUI"
# Should return results

# If search fails, keys don't match
```

### Rollback Steps

1. **Restore previous version**
   ```bash
   git revert v1.1.0
   git tag v1.1.0-rollback
   git push origin main
   git push origin v1.1.0-rollback
   ```

2. **Re-release with previous key**
   ```bash
   # Use previous PROD_KEY that worked
   # Re-encrypt data with previous key
   # Trigger new release build
   ```

3. **Root cause analysis**
   - Check GitHub Actions logs
   - Verify key length and format
   - Ensure data file wasn't corrupted

---

## Monthly Operational Tasks

### First Week of Month

- [ ] **Check releases are working**
  ```bash
  # Download latest binary and test
  sosumi search "SwiftUI"
  ```

- [ ] **Review GitHub Issues**
  - Check for decryption problems
  - Verify no security issues reported
  - Plan fixes for next release

### Monthly (Ongoing)

- [ ] **Monitor GitHub Secrets**
  - Verify SOSUMI_ENCRYPTION_KEY still exists
  - Check GitHub Security logs for access
  - Plan key rotation (annually minimum)

- [ ] **Update documentation**
  - Keep KEY_MANAGEMENT.md current
  - Document any changes
  - Update version numbers

---

## Annual Tasks

### Yearly Key Rotation

- [ ] **Schedule rotation** (e.g., Nov 18 annually)
  ```bash
  echo "2026-11-18" > KEY_ROTATION_SCHEDULED.txt
  git add KEY_ROTATION_SCHEDULED.txt
  ```

- [ ] **Generate new key**
  ```bash
  NEW_KEY=$(openssl rand -hex 16)
  echo "New key for 2026: $NEW_KEY"
  ```

- [ ] **Update GitHub Secret**
  - Settings → Secrets → SOSUMI_ENCRYPTION_KEY
  - Update with new value

- [ ] **Re-encrypt data**
  ```bash
  export SOSUMI_OBFUSCATION_KEY="$NEW_KEY"
  swift Scripts/obfuscate-data.swift \
    SourceData/wwdc_all_sessions.json \
    Outputs/wwdc_sessions_rotated.json.compressed
  ```

- [ ] **Release with new key**
  ```bash
  # New binaries built with new key
  # Old binaries still work
  # New data works with new key
  ```

---

## Incident Response

### If Encryption Key Is Compromised

**Severity**: HIGH - Immediate action required

**Steps**:

1. **Immediately**
   - Delete current GitHub Secret
   - Notify team members
   - Document timeline

2. **Within 1 Hour**
   - Generate new encryption key
   - Update GitHub Secret
   - Stop builds

3. **Within 24 Hours**
   - Re-encrypt all data with new key
   - Release new binaries
   - Notify users to update

4. **Post-Incident**
   - Root cause analysis
   - Implement additional safeguards
   - Update security documentation

---

## Success Criteria

After release, verify:

- ✅ Users can download binary from releases page
- ✅ Binary works without configuration
- ✅ Search results are correct
- ✅ Decryption works for all sessions
- ✅ No errors in GitHub Issues
- ✅ Performance is acceptable
- ✅ No security vulnerabilities reported

---

## Contacts

- **Build/Ops Issues**: [DevOps Team]
- **Security Questions**: [Security Team]
- **Code Review**: [Engineering Team]

---

**Next Steps**:
1. Review this checklist
2. Set up GitHub Secrets
3. Encrypt production data
4. Create release tag
5. Monitor GitHub Actions
6. Verify release works

**Timeline**: ✅ Ready for immediate deployment
