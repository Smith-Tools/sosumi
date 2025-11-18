# WWDC Database Setup

sosumi requires a WWDC transcript database to function. This document explains how to set it up.

## Quick Start

The database is stored in your home directory: `~/.sosumi/wwdc.db`

### Option 1: Download Pre-built Database (Recommended)

Coming in v1.3.0 release - encrypted bundle with embedded decryption key.

```bash
# Download will be provided in release notes
# Extract to ~/.sosumi/
mkdir -p ~/.sosumi
# Extract here
```

### Option 2: Build Database Locally

If you have the `sosumi-data-obfuscation` tools available:

```bash
cd /path/to/sosumi-data-obfuscation
make all  # Fetches, transcripts, builds database (2-3 hours)
cp Outputs/wwdc.db ~/.sosumi/
```

## Database Details

**Location:** `~/.sosumi/wwdc.db`

**Contents:**
- 3,215 WWDC sessions (2007-2025)
- 1,355 transcripts with full-text search index
- 4.7M words of content
- 30MB SQLite database

**Schema:**
```sql
sessions(id, title, year, event_id, session_number, duration, description, web_url, type)
transcripts(session_id, language, content, word_count, url, download_timestamp)
transcripts_fts(session_id, title, content, session_type, year, session_number, duration)
```

## How sosumi Uses It

sosumi looks for the database in this order:

1. **Plain database** - `~/.sosumi/wwdc.db` (for development)
2. **Encrypted bundle** - `~/.sosumi/wwdc_bundle.encrypted` (from releases)
3. Fails gracefully with instructions if neither found

## Building from Source

### Prerequisites

- Swift 6.0+
- curl, jq, sqlite3
- ~100GB disk space during build (~30GB final)
- 2-3 hours for full pipeline

### Build Steps

```bash
cd sosumi-data-obfuscation

# Stage 1: Fetch metadata from Apple CDN (3 min)
make fetch

# Stage 2: Download transcripts (1-2 hours)
make download

# Stage 3: Build SQLite database (15 min)
make build

# Output: Outputs/wwdc.db
cp Outputs/wwdc.db ~/.sosumi/
```

### Troubleshooting

**No sessions found:**
- Check internet connection
- Verify Apple CDN endpoints are accessible
- See `WWDC_DATA_PIPELINE.md` in sosumi-data-obfuscation

**Build fails:**
- Check `Outputs/` directory for partial data
- Run individual stages separately
- See BUILD_STATUS document for known issues

## For Developers

### Testing Plain Database Locally

```bash
# Database must be at ~/.sosumi/wwdc.db
ls -lh ~/.sosumi/wwdc.db

# Test search
sosumi search "SwiftUI"

# Test by year
sosumi sessions 2024
```

### Verifying Database Integrity

```bash
sqlite3 ~/.sosumi/wwdc.db "SELECT COUNT(*) FROM sessions; SELECT COUNT(*) FROM transcripts WHERE content IS NOT NULL;"

# Expected output:
# 3215
# 1355
```

### Full-Text Search Test

```bash
sqlite3 ~/.sosumi/wwdc.db "SELECT title, year FROM transcripts_fts WHERE transcripts_fts MATCH 'SwiftUI' LIMIT 5;"
```

## Database Lifecycle

| Version | Format | Distribution | Key Management |
|---------|--------|--------------|-----------------|
| v1.2.0 | Encrypted Bundle | GitHub Release | GitHub Secrets |
| v1.3.0+ | Plain (dev) + Encrypted (release) | Hybrid | Embedded in binary |

## Privacy & Legal

- Data sourced from Apple's public WWDC API
- Plain database should never be committed to public repos
- Encrypted bundle provides obfuscation for distribution
- See LICENSE for usage terms

## References

- Apple WWDC: https://developer.apple.com/videos/
- sosumi-data-obfuscation: Building pipeline documentation
- WWDC_DATA_PIPELINE.md: Technical details of data fetching

---

**Last Updated:** November 19, 2025
**sosumi Version:** 1.3.0+
