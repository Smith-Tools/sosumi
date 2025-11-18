# 🔒 Sosumi Security Requirements

## **CRITICAL: Key Management**

This repository contains **encrypted WWDC data** that requires proper key management for production deployment.

## **Security Architecture**

- **Content**: AES-256-GCM encrypted session transcripts
- **Titles**: Readable for search functionality (users need to find sessions)
- **Storage**: LZFSE compressed for efficient distribution
- **Key Protection**: Keys embedded in compiled binary, not exposed in source

## **🎯 GOAL: Public Tool + Protected Source**

**Requirement**: Users should get **full functionality** without any setup, but the source data should be **protected in public repositories**.

## **⚠️ PRODUCTION DEPLOYMENT STRATEGY**

### **The Problem:**
- ❌ Data must be encrypted in public repository
- ❌ Tool must work without user configuration
- ❌ Keys cannot be exposed in source code

### **The Solution: Build-Time Key Injection**

#### **Option 1: Swift Build Flags (Recommended)**
```bash
# Build with embedded key
swift build -Xswiftc -DSOSUMI_KEY='"your-secure-key-here"'

# In code:
#if SOSUMI_KEY
private static let key = SOSUMI_KEY
#else
fatalError("No encryption key available")
#endif
```

#### **Option 2: Secure Build Pipeline**
```yaml
# GitHub Actions / CI/CD example
- name: Build with encrypted data
  run: |
    echo "${{ secrets.SOSUMI_ENCRYPTION_KEY }}" > build_key.txt
    swift build -Xswiftc -DSOSUMI_KEY="$(cat build_key.txt)"
    rm build_key.txt  # Clean up
```

#### **Option 3: Code Signing with Embedded Data**
- Embed key as encrypted resource in app bundle
- Use app signature to decrypt key at runtime
- Most secure but most complex

## **✅ What This Achieves:**

1. **Public Repository Safe**:
   - ✅ Source code contains NO encryption keys
   - ✅ Encrypted data file contains gibberish without key
   - ✅ Full source can be publicly shared

2. **User Experience**:
   - ✅ Tool works immediately after download/build
   - ✅ Full search and transcript access
   - ✅ No configuration required

3. **Security**:
   - ✅ Keys only exist in compiled binary
   - ✅ Source data is protected in repository
   - ✅ Keys not exposed in source code

## **🚫 NEVER DO THIS**

❌ **Hardcode keys in source code** (current demo implementation)
❌ **Commit keys to git repository**
❌ **Store keys in plain text files**
❌ **Use predictable keys** (change "12345678901234567890123456789012")

## **🔧 Key Generation**

Generate cryptographically secure keys:
```bash
# Using OpenSSL
openssl rand -hex 32

# Using Swift (in secure environment)
import CryptoKit
let key = SymmetricKey(size: .bits256)
let keyString = key.withUnsafeBytes { Data($0).base64EncodedString() }
```

## **📋 Production Checklist**

- [ ] Remove hardcoded demo key from `ContentDecryptor.swift`
- [ ] Implement secure key retrieval (environment variable or keychain)
- [ ] Set up key in deployment environment
- [ ] Test decryption with production key
- [ ] Verify key is not accessible in source code
- [ ] Add key to secure secrets management system
- [ ] Document key rotation procedures

## **🔍 Security Verification**

```bash
# Verify content is encrypted (should be base64 gibberish)
swift check-security.swift Resources/DATA/wwdc_sessions_2024_enhanced.json.compressed

# Test with proper key
export SOSUMI_DECRYPTION_KEY="your-production-key"
./sosumi wwdc "SharePlay"

# Test without key (should fail)
unset SOSUMI_DECRYPTION_KEY
./sosumi wwdc "SharePlay"  # Should return decryption error
```

## **🆘 Key Rotation**

When rotating encryption keys:
1. Generate new secure key
2. Re-encrypt all data with new key
3. Update key in secure storage
4. Deploy updated encrypted data file
5. Test with new key
6. Securely destroy old key

## **⚡ Current Status**

- ✅ Content properly encrypted with AES-256-GCM
- ✅ Titles obfuscated with character substitution
- ✅ Data compressed with LZFSE
- ⚠️ **Key management needs production implementation**
- ⚠️ **Demo key MUST be removed for production**

---

**🔒 Remember: Security is only as strong as your key management practices!**