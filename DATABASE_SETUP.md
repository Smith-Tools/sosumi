# WWDC Database Setup

sosumi requires a WWDC transcript database to function. This document explains how to set it up.

## Database Locations

| Database | Path | Purpose |
|----------|------|---------|
| **WWDC Source** | `~/.claude/resources/databases/wwdc.db` | Primary WWDC session/transcript DB |
| **RAG Embeddings** | `~/.smith/rag/sosumi.db` | Vector embeddings for semantic search |
| **Source Data** | `sosumi-data-private/Outputs/wwdc.db` | Development source (not distributed) |

## Quick Start

### Option 1: Download Production Binary (Recommended)

The production binary includes encrypted WWDC data. No database setup needed.

```bash
# Download from releases
wget https://github.com/Smith-Tools/sosumi/releases/latest/download/sosumi
chmod +x sosumi
./sosumi search "SwiftUI"
```

### Option 2: Claude Skill Installation

For Claude Code integration:

```bash
mkdir -p ~/.claude/resources/databases/
# Copy database from sosumi-data-private or decrypt from bundle
cp /path/to/wwdc.db ~/.claude/resources/databases/
```

### Option 3: Build Database Locally

If you have the `sosumi-data-private` tools:

```bash
cd sosumi-data-private
make all  # Fetches, transcripts, builds database (2-3 hours)
# Output: Outputs/wwdc.db (207MB)
```

## Database Details

**Contents:**
- 3,228 WWDC sessions (2014-2025)
- 1,373 transcripts with full-text search index (FTS5)
- 4.7M words of content
- ~207MB SQLite database

**Schema:**
```sql
sessions(id, title, year, event_id, session_number, duration, description, web_url, type)
transcripts(session_id, language, content, word_count, url, download_timestamp)
transcripts_fts(session_id, title, content, session_type, year, session_number, duration)
```

## RAG (Semantic Search) Setup

For semantic/embedding-based search via `sosumi rag-search`:

```bash
# 1. Ensure WWDC source DB exists
ls ~/.claude/resources/databases/wwdc.db

# 2. Ingest transcripts into RAG
sosumi ingest-rag --limit 2000

# 3. Generate embeddings (requires Ollama running)
sosumi embed-missing --limit 3000 --batch-size 100

# 4. Test semantic search
sosumi rag-search "building immersive visionOS experiences"
```

**RAG Database:** `~/.smith/rag/sosumi.db`
- 14,100 chunks from 1,355 sessions
- Vector embeddings via nomic-embed-text
- ~140MB with full embeddings

## How sosumi Finds Databases

sosumi looks for databases in this order:

1. **Plain database** - `~/.claude/resources/databases/wwdc.db` (v1.3.0+)
2. **Encrypted bundle** - `Resources/DATA/wwdc_bundle.encrypted` (in binary)
3. Fails gracefully with instructions if neither found

## For Developers

### Testing Database Locally

```bash
# Ensure database exists
ls -lh ~/.claude/resources/databases/wwdc.db

# Test FTS search
sosumi wwdc "SwiftUI"

# Test year listing
sosumi year 2024

# Test RAG search
sosumi rag-search "async await concurrency"
```

### Verifying Database Integrity

```bash
DB=~/.claude/resources/databases/wwdc.db
sqlite3 "$DB" "SELECT COUNT(*) FROM sessions;"
# Expected: 3228

sqlite3 "$DB" "SELECT COUNT(*) FROM transcripts;"
# Expected: 1373
```

### Full-Text Search Test

```bash
sqlite3 ~/.claude/resources/databases/wwdc.db \
  "SELECT title, year FROM transcripts_fts WHERE transcripts_fts MATCH 'SwiftUI' LIMIT 5;"
```

## Privacy & Legal

- Data sourced from Apple's public WWDC API
- Plain database should never be committed to public repos
- Encrypted bundle provides obfuscation for distribution
- See LICENSE for usage terms

## References

- Apple WWDC: https://developer.apple.com/videos/
- sosumi-data-private: Building pipeline documentation

---

**Last Updated:** December 12, 2025
**sosumi Version:** 2.0.0+
