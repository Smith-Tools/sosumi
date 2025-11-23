#!/bin/bash

set -e

echo "🚀 Sosumi LOCAL Skill Deployment (Repository → Local Claude Skill)"
echo "========================================================="
echo "📍 LOCAL ONLY: This script deploys sosumi to your local Claude skills directory"
echo "🔧 Version Controlled: This script lives in the repository (Scripts/deploy-skill.sh)"
echo ""

# Configuration
SOSUMI_SOURCE="/Volumes/Plutonian/_Developer/Smith Tools/sosumi"
LOCAL_SKILL_DIR="/Users/elkraneo/.claude/skills/sosumi"
LOCAL_BIN_DIR="$HOME/.local/bin"
DB_DIR="$HOME/.claude/resources/databases"

# Validate source directory
if [ ! -d "$SOSUMI_SOURCE" ]; then
    echo "❌ Sosumi source not found: $SOSUMI_SOURCE"
    exit 1
fi

echo "📋 Source validated: $SOSUMI_SOURCE"

# 1. Clean previous installation
echo "🧹 Cleaning previous installation..."
rm -rf "$LOCAL_SKILL_DIR"
mkdir -p "$LOCAL_SKILL_DIR"
mkdir -p "$LOCAL_BIN_DIR"
mkdir -p "$DB_DIR"

# 2. Build the sosumi CLI
echo "🔨 Building sosumi CLI from source..."
cd "$SOSUMI_SOURCE"
swift build -c release

# 3. Install binary to local bin
echo "📦 Installing CLI binary..."
cp .build/release/sosumi "$LOCAL_BIN_DIR/"

# 4. Setup PATH
if [[ ":$PATH:" != *":$LOCAL_BIN_DIR:"* ]]; then
    echo "🔗 Adding $LOCAL_BIN_DIR to PATH..."
    echo "export PATH=\"$LOCAL_BIN_DIR:\$PATH\"" >> ~/.zshrc 2>/dev/null || echo "export PATH=\"$LOCAL_BIN_DIR:\$PATH\"" >> ~/.bashrc 2>/dev/null
    export PATH="$LOCAL_BIN_DIR:$PATH"
fi

# 5. Create proper Claude skill structure
echo "🏗️  Creating Claude skill structure..."

# Create subdirectories per Claude skill specification
mkdir -p "$LOCAL_SKILL_DIR/scripts"
mkdir -p "$LOCAL_SKILL_DIR/data"

# Install current compiled CLI binary to scripts/ directory
echo "📦 Installing current compiled binary to scripts/..."
cp "$SOSUMI_SOURCE/.build/release/sosumi" "$LOCAL_SKILL_DIR/scripts/"
chmod +x "$LOCAL_SKILL_DIR/scripts/sosumi"

# Copy essential documentation artifacts
echo "📚 Installing documentation..."
cd "$SOSUMI_SOURCE"
cp README.md "$LOCAL_SKILL_DIR/reference.md" 2>/dev/null || echo "README.md not found"

# Install database to skill data directory
# Verify database exists in expected location (do NOT bundle in skill)
echo "🗄️  Verifying database installation..."
if [ -f "$DB_DIR/wwdc.db" ]; then
    echo "✅ Database found at $DB_DIR/wwdc.db"
    echo "   • Database size: $(du -h "$DB_DIR/wwdc.db" | cut -f1)"
else
    echo "⚠️  Database not found at $DB_DIR/wwdc.db"
    echo "   WWDC search functionality will not work until database is installed"
    echo "   Run: ./scripts/setup-database.sh to install the database"
fi

# Create working search script with enhanced diagnostics and logging
echo "🔧 Creating working search script..."
cat > "$LOCAL_SKILL_DIR/scripts/search.sh" << 'EOF'
#!/bin/bash
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_DOCS_LIMIT="${SOSUMI_DOCS_LIMIT:-5}"
DEFAULT_WWDC_LIMIT="${SOSUMI_WWDC_LIMIT:-6}"
DEFAULT_WWDC_VERBOSITY="${SOSUMI_WWDC_VERBOSITY:-compact}"
SOSUMI_CACHE_DIR="${HOME}/.sosumi/cache"
SOSUMI_LOG_DIR="${HOME}/.sosumi/logs"

# Initialize directories
mkdir -p "$SOSUMI_CACHE_DIR" 2>/dev/null || true
mkdir -p "$SOSUMI_LOG_DIR" 2>/dev/null || true

log_error() {
    local error_msg="$1"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    echo "$timestamp - $error_msg" >> "$SOSUMI_LOG_DIR/errors.log" 2>/dev/null || true
}

diagnose_setup() {
    local issues=()

    # Check binary exists
    if [ ! -f "$SOSUMI_BIN" ]; then
        issues+=("❌ Binary not found: $SOSUMI_BIN")
    elif [ ! -x "$SOSUMI_BIN" ]; then
        issues+=("❌ Binary not executable (permission issue)")
        issues+=("💡 Try: chmod +x $SOSUMI_BIN")
    fi

    # Check WWDC database for WWDC commands
    if [ ! -f "$HOME/.sosumi/wwdc.db" ]; then
        issues+=("❌ WWDC database missing: $HOME/.sosumi/wwdc.db")
        issues+=("💡 Run: ~/.claude/skills/sosumi/scripts/setup-database.sh")
    fi

    if [ ${#issues[@]} -gt 0 ]; then
        printf '%s\n' "${issues[@]}"
        return 1
    fi

    return 0
}

find_sosumi() {
    if command -v sosumi >/dev/null 2>&1; then
        command -v sosumi
        return
    fi

    if [ -x "$SCRIPT_DIR/sosumi" ]; then
        echo "$SCRIPT_DIR/sosumi"
        return
    fi

    echo ""
}

SOSUMI_BIN="$(find_sosumi)"

if [ -z "$SOSUMI_BIN" ]; then
    echo "❌ Sosumi binary not found at: $SCRIPT_DIR/sosumi"
    echo "💡 Re-run deploy-skill.sh or check installation"
    log_error "Binary not found: $SCRIPT_DIR/sosumi"
    exit 1
fi

# Verify binary is executable
if ! [ -x "$SOSUMI_BIN" ]; then
    echo "❌ Sosumi binary not executable (permission issue)"
    echo "💡 Run: chmod +x $SOSUMI_BIN"
    log_error "Binary not executable: $SOSUMI_BIN"
    exit 1
fi

run_cli() {
    "$SOSUMI_BIN" "$@"
}

extract_wwdc_session_id() {
    local url="$1"

    # Match patterns like:
    # https://developer.apple.com/videos/play/wwdc2023/10087/
    # https://developer.apple.com/videos/play/wwdc2024-10150
    # https://developer.apple.com/videos/play/tech-talks-110338

    if [[ "$url" =~ developer\.apple\.com/videos/play/([a-z0-9-]+/?[0-9]+) ]]; then
        local extracted="${BASH_REMATCH[1]}"
        # Normalize: remove trailing slash and format as wwdcYYYY-ID
        extracted="${extracted%/}"
        # If it's just tech-talks-XXXXX format, keep as is
        if [[ "$extracted" =~ ^tech-talks- ]]; then
            echo "$extracted"
        else
            # Convert wwdc2023/10087 to wwdc2023-10087
            echo "${extracted//\//-}"
        fi
        return 0
    fi

    return 1
}

is_wwdc_url() {
    local query="$1"
    [[ "$query" =~ developer\.apple\.com/videos/play/ ]]
}

is_doc_identifier() {
    local query="$1"

    # Check if it's a URL (http://, https://, //)
    if [[ "$query" =~ ^(https?://|//) ]]; then
        return 0
    fi

    # Check if it's a doc:// URL
    if [[ "$query" =~ ^doc:// ]]; then
        return 0
    fi

    # Check if it's a path-like identifier (design/*, documentation/*, swiftui/*, etc.)
    # Must have at least one slash and not be just words
    if [[ "$query" =~ ^[a-z0-9-]+/[a-z0-9/-]+ ]]; then
        return 0
    fi

    return 1
}

run_docs_section() {
    local query="$1"
    local limit="$2"

    # Smart routing: if it looks like a specific page identifier/URL, fetch it directly
    if is_doc_identifier "$query"; then
        run_cli doc "$query"
        return
    fi

    # Otherwise, perform search
    local args=(docs "$query")
    if [ -n "$limit" ]; then
        args+=(--limit "$limit")
    fi

    if ! run_cli "${args[@]}"; then
        echo "⚠️ Apple documentation search failed. Check network connectivity."
        log_error "Docs search failed: $query"
    fi
}

run_wwdc_section() {
    local query="$1"
    local limit="$2"
    local verbosity="${3:-$DEFAULT_WWDC_VERBOSITY}"

    # Verify database exists before calling binary
    if [ ! -f "$HOME/.sosumi/wwdc.db" ]; then
        echo "⚠️ WWDC database not found at: $HOME/.sosumi/wwdc.db"
        echo "💡 Run: ~/.claude/skills/sosumi/scripts/setup-database.sh"
        log_error "WWDC database missing"
        return 1
    fi

    local args=(wwdc "$query" --verbosity "$verbosity")
    if [ -n "$limit" ]; then
        args+=(--limit "$limit")
    fi

    if ! run_cli "${args[@]}"; then
        echo "⚠️ WWDC search failed. Database may be corrupted."
        log_error "WWDC search failed: $query"
        return 1
    fi
}

run_combined_search() {
    local query="$1"
    local doc_limit="${2:-$DEFAULT_DOCS_LIMIT}"
    local wwdc_limit="${3:-$DEFAULT_WWDC_LIMIT}"

    # Note: WWDC URLs in search should return compact results + session ID
    # If agent wants full transcript, they should use: search.sh transcript <url>
    # This keeps search efficient and discovery-focused

    echo "🔎 Sosumi Search: \"$query\""
    echo "=================================================="
    echo "📚 Apple Documentation"
    run_docs_section "$query" "$doc_limit"
    echo
    echo "🎥 WWDC Sessions"
    run_wwdc_section "$query" "$wwdc_limit" "$DEFAULT_WWDC_VERBOSITY"
    echo
    echo "💡 Tip: Use 'transcript <url>' or 'transcript <session-id>' to get full transcripts"
}

run_search_command() {
    local type="combined"
    local shared_limit=""
    local doc_limit=""
    local wwdc_limit=""
    local query_parts=()

    while [ $# -gt 0 ]; do
        case "$1" in
            --type)
                type="${2:-combined}"
                shift 2
                ;;
            --limit)
                shared_limit="${2:-}"
                shift 2
                ;;
            --docs-limit)
                doc_limit="${2:-}"
                shift 2
                ;;
            --wwdc-limit)
                wwdc_limit="${2:-}"
                shift 2
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            *)
                query_parts+=("$1")
                shift
                ;;
        esac
    done

    local query="${query_parts[*]}"

    if [ -z "$query" ]; then
        echo "❌ Missing search query."
        exit 1
    fi

    local final_doc_limit="${doc_limit:-${shared_limit:-$DEFAULT_DOCS_LIMIT}}"
    local final_wwdc_limit="${wwdc_limit:-${shared_limit:-$DEFAULT_WWDC_LIMIT}}"

    case "$type" in
        docs|documentation)
            run_docs_section "$query" "$final_doc_limit"
            ;;
        wwdc|sessions)
            run_wwdc_section "$query" "$final_wwdc_limit" "$DEFAULT_WWDC_VERBOSITY"
            ;;
        combined|all|both|search|auto)
            run_combined_search "$query" "$final_doc_limit" "$final_wwdc_limit"
            ;;
        *)
            echo "⚠️ Unknown search type \"$type\". Defaulting to combined."
            run_combined_search "$query" "$final_doc_limit" "$final_wwdc_limit"
            ;;
    esac
}

show_usage() {
    cat <<'USAGE'
Usage:
  search.sh transcript <url-or-id>     # Get WWDC transcript (⭐ preferred for videos)
  search.sh search <query> [--type docs|wwdc|combined] [--limit N]
  search.sh docs <query> [--limit N]
  search.sh doc <path> [--format markdown|json]
  search.sh wwdc <query> [--limit N] [--verbosity compact|detailed|full]
  search.sh session <session-id>
  search.sh year <year>
  search.sh stats
  search.sh test
  search.sh update
  search.sh diagnose                   # Check installation and health
  search.sh <query>                # Combined search (docs + WWDC) using defaults

Transcript Command (Layer 3 - Primary interface for agents):
  Accepts WWDC video URLs and session IDs:
  - search.sh transcript https://developer.apple.com/videos/play/wwdc2023/10087/
  - search.sh transcript wwdc2023-10087
  - search.sh transcript tech-talks-110338

Environment overrides:
  SOSUMI_DOCS_LIMIT       Default docs results (default: 5)
  SOSUMI_WWDC_LIMIT       Default WWDC results (default: 6)
  SOSUMI_WWDC_VERBOSITY   WWDC verbosity (default: compact)
USAGE
}

show_diagnostics() {
    echo "🔍 Sosumi Diagnostics"
    echo "=================================================="

    # Binary check
    if [ -f "$SOSUMI_BIN" ]; then
        echo "✅ Binary found: $SOSUMI_BIN"
        if [ -x "$SOSUMI_BIN" ]; then
            echo "✅ Binary is executable"
            local size=$(stat -f%z "$SOSUMI_BIN" 2>/dev/null || stat -c%s "$SOSUMI_BIN" 2>/dev/null)
            echo "📏 Binary size: $(( size / 1024 / 1024 )) MB"
        else
            echo "❌ Binary not executable (fix: chmod +x $SOSUMI_BIN)"
        fi
    else
        echo "❌ Binary not found: $SOSUMI_BIN"
    fi

    echo ""

    # Database check
    if [ -f "$HOME/.sosumi/wwdc.db" ]; then
        echo "✅ WWDC database found: $HOME/.sosumi/wwdc.db"
        local db_size=$(stat -f%z "$HOME/.sosumi/wwdc.db" 2>/dev/null || stat -c%s "$HOME/.sosumi/wwdc.db" 2>/dev/null)
        echo "📏 Database size: $(( db_size / 1024 / 1024 )) MB"
    else
        echo "❌ WWDC database not found: $HOME/.sosumi/wwdc.db"
        echo "💡 Run: ~/.claude/skills/sosumi/scripts/setup-database.sh"
    fi

    echo ""

    # Cache check
    if [ -d "$SOSUMI_CACHE_DIR" ]; then
        local cache_count=$(find "$SOSUMI_CACHE_DIR" -type f 2>/dev/null | wc -l)
        echo "📦 Cache files: $cache_count"
        if [ "$cache_count" -gt 0 ]; then
            local cache_size=$(du -sh "$SOSUMI_CACHE_DIR" 2>/dev/null | cut -f1)
            echo "💾 Cache size: $cache_size"
        fi
    fi

    echo ""

    # Error log check
    if [ -f "$SOSUMI_LOG_DIR/errors.log" ]; then
        local error_count=$(wc -l < "$SOSUMI_LOG_DIR/errors.log" 2>/dev/null || echo 0)
        echo "📋 Error log entries: $error_count"
        if [ "$error_count" -gt 0 ]; then
            echo "   Recent errors:"
            tail -3 "$SOSUMI_LOG_DIR/errors.log" | sed 's/^/   /'
        fi
    else
        echo "✅ No errors logged"
    fi

    echo "=================================================="
}

COMMAND="${1:-}"

if [ -z "$COMMAND" ]; then
    show_usage
    exit 1
fi

case "$COMMAND" in
    transcript)
        shift
        if [ $# -eq 0 ]; then
            echo "❌ Missing WWDC URL or session ID."
            echo "Usage: search.sh transcript <url-or-session-id>"
            echo ""
            echo "Examples:"
            echo "  search.sh transcript https://developer.apple.com/videos/play/wwdc2023/10087/"
            echo "  search.sh transcript wwdc2023-10087"
            exit 1
        fi

        input="$1"

        # If it's a WWDC URL, extract the session ID
        if is_wwdc_url "$input"; then
            if session_id=$(extract_wwdc_session_id "$input"); then
                run_cli session "$session_id" --mode agent
            else
                echo "❌ Could not extract session ID from URL: $input"
                exit 1
            fi
        else
            # Otherwise, treat it as a session ID directly
            run_cli session "$input" --mode agent
        fi
        ;;
    search)
        shift
        run_search_command "$@"
        ;;
    docs)
        shift
        if [ $# -eq 0 ]; then
            echo "❌ Missing documentation search query."
            exit 1
        fi
        # Use run_docs_section for smart routing (URL detection)
        run_docs_section "$1" "${2:-}"
        ;;
    doc|fetch)
        shift
        if [ $# -eq 0 ]; then
            echo "❌ Missing documentation path."
            exit 1
        fi
        run_cli doc "$@"
        ;;
    wwdc|session|year|stats|test|update)
        run_cli "$@"
        ;;
    diagnose)
        show_diagnostics
        ;;
    combined)
        shift
        if [ $# -eq 0 ]; then
            echo "❌ Missing search query."
            exit 1
        fi
        run_combined_search "$*"
        ;;
    -h|--help|help)
        show_usage
        ;;
    *)
        run_combined_search "$*"
        ;;
esac
EOF
chmod +x "$LOCAL_SKILL_DIR/scripts/search.sh"
# Create setup script for database (copied from external source)
cat > "$LOCAL_SKILL_DIR/scripts/setup-database.sh" << EOF
#!/bin/bash
# Setup database for sosumi skill - download from external source
DB_DIR="$HOME/.claude/resources/databases"
GITHUB_REPO="Smith-Tools/sosumi-data-private"
DB_FILE="wwdc.db"
DB_URL="https://github.com/$GITHUB_REPO/releases/latest/download/$DB_FILE"

echo "Setting up sosumi database..."
mkdir -p "$DB_DIR"

if [ -f "$DB_DIR/$DB_FILE" ]; then
    echo "✅ Database already exists at $DB_DIR/$DB_FILE"
    echo "   Database size: $(du -h "$DB_DIR/$DB_FILE" | cut -f1)"
else
    echo "📥 Downloading database from $GITHUB_REPO..."
    if command -v curl >/dev/null 2>&1; then
        curl -L "$DB_URL" -o "$DB_DIR/$DB_FILE"
        echo "✅ Database downloaded to $DB_DIR/$DB_FILE"
    elif command -v wget >/dev/null 2>&1; then
        wget "$DB_URL" -O "$DB_DIR/$DB_FILE"
        echo "✅ Database downloaded to $DB_DIR/$DB_FILE"
    else
        echo "❌ Neither curl nor wget available. Please download manually:"
        echo "   URL: $DB_URL"
        echo "   Destination: $DB_DIR/$DB_FILE"
        exit 1
    fi
fi
EOF
chmod +x "$LOCAL_SKILL_DIR/scripts/setup-database.sh"
EOF
chmod +x "$LOCAL_SKILL_DIR/scripts/setup-database.sh"

# Create proper SKILL.md following Claude skill specification
cat > "$LOCAL_SKILL_DIR/SKILL.md" << 'EOF'
---
name: sosumi
description: Search Apple developer documentation and WWDC sessions. Automatically triggers on: SwiftUI, Combine, Core Data, SharePlay, @State, @Published, async/await, UIKit, AppKit, visionOS, iOS development, Apple APIs, WWDC questions.
allowed-tools: [Bash, Read, Write, Glob]
executables: ["./scripts/search.sh"]
---

# Apple Documentation & WWDC Search

Search both Apple Developer documentation (real-time) and WWDC session archive with intelligent query routing. Clean CLI interface with automatic routing to working WWDC content.

## Usage Examples

**Automatic Skill Usage** (just ask naturally):
- "How do I use @State in SwiftUI?"
- "What's the difference between @StateObject and @ObservedObject?"
- "Show me Combine publishers and subscribers"
- "Find sessions about SharePlay"
- "Get session wwdc2024-10150"
- "List WWDC sessions from 2024"
- "Tell me about SwiftUI state management"
- "What's new in iOS 18 APIs?"

**✅ Guaranteed Working**:
- **WWDC Sessions**: 3,215+ sessions with full transcripts
- **Session Lookup**: By ID (wwdc2024-10150, tech-talks-110338)
- **Year Browsing**: All WWDC years (2014-2025)
- **Framework Search**: SwiftUI, Combine, Core Data, Metal, ARKit, etc.
- **Local Database**: Always works, no network required

**🎯 Auto-Routing Logic**:
- Framework keywords → WWDC search (comprehensive coverage)
- Session IDs → Direct session lookup
- Year references → Year browsing
- API questions → WWDC practical examples
- General queries → Intelligent search

## Technical Details

This skill uses a compiled CLI tool located in `scripts/sosumi` that provides:

### Apple Documentation (NEW)
- **Real-time API access** to Apple Developer documentation
- **Full search across frameworks** (SwiftUI, Combine, SwiftData, etc.)
- **JSON-to-Markdown rendering** with proper formatting
- **Network-based retrieval** with Safari user agent rotation

### WWDC Session Archive
- **Full-text search** across 3,215 sessions with BM25 relevance ranking
- **Direct session lookup** with complete transcripts (1,355 sessions)
- **Year-based browsing** with formatted listings
- **Database statistics** and content analysis
- **SQLite FTS5** with optimized search performance
- **Local processing** for offline access

## Database Coverage

- **Sessions**: 3,215 (2014-2025)
- **Transcripts**: 1,355 with full text
- **Word Count**: 4.7M searchable words
- **Platforms**: iOS, macOS, watchOS, tvOS, visionOS
- **Frameworks**: SwiftUI, UIKit, AppKit, Combine, Core Data, Metal

## Session ID Formats

- **WWDC sessions**: `wwdc2024-10150`, `wwdc2023-10187`
- **Tech Talks**: `tech-talks-110338`
- **Direct numeric**: `10150`, `110338`

## Files

- `scripts/sosumi` - Compiled CLI binary with full search capabilities
- `scripts/search.sh` - Working search script with intelligent routing
- `scripts/setup-database.sh` - Database setup script
- `data/wwdc.db` - SQLite database (if included)
- `reference.md` - Complete project documentation

## Dependencies

- SQLite database with FTS5 extension
- WWDC session data (installed via setup script)
- Compiled Swift binary (included)

For advanced usage and technical details, see [reference.md](reference.md).

---

*Built from source with SQLite FTS5 and BM25 ranking. Visit [GitHub](https://github.com/Smith-Tools/sosumi) for source code.*
EOF

# 6. Verify installation
echo "🧪 Verifying complete installation..."
if command -v sosumi >/dev/null 2>&1; then
    echo "✅ CLI tool accessible"

    # Test database connection
    if sosumi stats >/dev/null 2>&1; then
        echo "✅ Database connection working"

        # Get actual stats
        STATS=$(sosumi stats)
        SESSION_COUNT=$(echo "$STATS" | grep "Total Sessions" | awk '{print $3}')
        TRANSCRIPT_COUNT=$(echo "$STATS" | grep "Sessions with Transcripts" | awk '{print $4}')

        echo ""
        echo "📊 Database Statistics:"
        echo "   • Total Sessions: $SESSION_COUNT"
        echo "   • With Transcripts: $TRANSCRIPT_COUNT"
        echo "   • Database Size: $(du -h "$DB_DIR/wwdc.db" 2>/dev/null | cut -f1 || echo "Unknown")"

    else
        echo "⚠️  Database connection issue - check $DB_DIR/wwdc.db"
        echo "   Try running: ./scripts/setup-database.sh"
    fi
else
    echo "❌ CLI tool not found in PATH"
    echo "Please restart your terminal or run: export PATH=\"$LOCAL_BIN_DIR:\$PATH\""
fi

echo ""
echo "🎉 Complete deployment finished!"
echo "==================================="
echo ""
echo "📍 Local Skill Directory: $LOCAL_SKILL_DIR"
echo "📍 CLI Tool: $LOCAL_BIN_DIR/sosumi"
echo "📍 Database: $DB_DIR/wwdc.db"
echo ""
echo "📖 Documentation available in: $LOCAL_SKILL_DIR"
echo "💡 Use with Claude: 'Search WWDC sessions for SwiftUI'"
echo "💡 Alternative: ./scripts/search.sh \"SharePlay\""
echo ""
echo "🔄 To update: Re-run this deployment script"
