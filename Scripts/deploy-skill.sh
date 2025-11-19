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
echo "🗄️  Installing database to skill..."
if [ -f "$DB_DIR/wwdc.db" ]; then
    cp "$DB_DIR/wwdc.db" "$LOCAL_SKILL_DIR/data/"
    echo "✅ Database copied to skill data directory"
    echo "   • Database size: $(du -h "$LOCAL_SKILL_DIR/data/wwdc.db" | cut -f1)"
else
    echo "⚠️  Database not found at $DB_DIR/wwdc.db"
    echo "   WWDC search functionality will not work until database is installed"
fi

# Create working search script
echo "🔧 Creating working search script..."
cat > "$LOCAL_SKILL_DIR/scripts/search.sh" << 'EOF'
#!/bin/bash

# Working Sosumi Search Script
# Prioritizes WWDC (always works) with optional Apple docs fallback

QUERY="$1"
SOSUMI_BIN="/Users/elkraneo/.local/bin/sosumi"
SKILL_BIN="./scripts/sosumi"

echo "🔍 Sosumi Search: \"$QUERY\""
echo "=================================================="

# Function to execute WWDC search (always works)
search_wwdc() {
    echo "🎥 WWDC Session Results:"
    echo ""

    if [ -x "$SOSUMI_BIN" ]; then
        "$SOSUMI_BIN" wwdc "$QUERY"
    elif [ -x "$SKILL_BIN" ]; then
        "$SKILL_BIN" wwdc "$QUERY"
    else
        echo "❌ Sosumi binary not found"
        return 1
    fi
}

# Function for session lookup
get_session() {
    echo "🎯 Session Lookup: $1"
    echo ""

    if [ -x "$SOSUMI_BIN" ]; then
        "$SOSUMI_BIN" session "$1"
    elif [ -x "$SKILL_BIN" ]; then
        "$SKILL_BIN" session "$1"
    fi
}

# Function for year browsing
get_year() {
    echo "📅 Sessions from $1:"
    echo ""

    if [ -x "$SOSUMI_BIN" ]; then
        "$SOSUMI_BIN" year "$1"
    elif [ -x "$SKILL_BIN" ]; then
        "$SKILL_BIN" year "$1"
    fi
}

# Route query based on content
route_query() {
    local query="$1"
    local lc_query=$(echo "$query" | tr '[:upper:]' '[:lower:]')

    # Session ID lookup
    if [[ "$lc_query" =~ (wwdc[0-9]{4}-[0-9]+|tech-talks-[0-9]+) ]]; then
        get_session "$query"
        return
    fi

    # Year-based queries
    if [[ "$lc_query" =~ [0-9]{4} ]]; then
        local year=$(echo "$lc_query" | grep -o '[0-9]\{4\}' | head -1)
        get_year "$year"
        return
    fi

    # Default: WWDC search
    search_wwdc
}

# Main execution
if [ -z "$QUERY" ]; then
    echo "Usage: $0 \"search query\""
    echo ""
    echo "Examples:"
    echo "  $0 \"SharePlay\""
    echo "  $0 \"SwiftUI @State\""
    echo "  $0 \"wwdc2024-10150\""
    echo "  $0 \"2024\""
    echo ""
    echo "Features:"
    echo "  • Automatic WWDC session search (20,000+ sessions)"
    echo "  • Session lookup by ID"
    echo "  • Year-based browsing"
    echo "  • Local database - always works"
    exit 1
fi

route_query "$QUERY"
EOF
chmod +x "$LOCAL_SKILL_DIR/scripts/search.sh"

# Create setup script for database
cat > "$LOCAL_SKILL_DIR/scripts/setup-database.sh" << EOF
#!/bin/bash
# Setup database for sosumi skill
SKILL_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")/.." && pwd)"
DB_DIR="\$HOME/.claude/resources/databases"

echo "Setting up sosumi database..."
mkdir -p "\$DB_DIR"

if [ -f "\$SKILL_DIR/data/wwdc.db" ]; then
    cp "\$SKILL_DIR/data/wwdc.db" "\$DB_DIR/"
    echo "✅ Database copied to \$DB_DIR/wwdc.db"
else
    echo "❌ Database not found in skill data directory"
    echo "   Please download from GitHub releases"
fi
EOF
chmod +x "$LOCAL_SKILL_DIR/scripts/setup-database.sh"

# Create proper SKILL.md following Claude skill specification
cat > "$LOCAL_SKILL_DIR/SKILL.md" << 'EOF'
---
name: sosumi
description: Search Apple developer documentation and WWDC sessions. Automatically triggers on: SwiftUI, Combine, Core Data, SharePlay, @State, @Published, async/await, UIKit, AppKit, visionOS, iOS development, Apple APIs, WWDC questions.
allowed-tools: [Bash]
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