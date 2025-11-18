# Makefile for sosumi
# Public build and installation targets

.PHONY: build install clean test help

# Default target
all: build

# Build the CLI tool
build:
	@echo "🔨 Building sosumi CLI..."
	swift build -c release
	@echo "✅ Build complete"
	@echo "Binary: .build/release/sosumi"

# Install sosumi (skill + CLI)
install: build
	@echo "🚀 Installing sosumi..."

	# Install CLI binary
	mkdir -p $(HOME)/.local/bin
	cp .build/release/sosumi $(HOME)/.local/bin/

	# Add to PATH if needed
	@if [[ ":$(PATH):" != *":$(HOME)/.local/bin:"* ]]; then \
		echo 'export PATH="$(HOME)/.local/bin:$$PATH"' >> $(HOME)/.zshrc; \
		echo 'export PATH="$(HOME)/.local/bin:$$PATH"' >> $(HOME)/.bash_profile; \
		echo "✅ Added ~/.local/bin to PATH"; \
	fi

	# Install Claude skill
	mkdir -p $(HOME)/.claude/skills
	cp SKILL.md $(HOME)/.claude/skills/sosumi.md

	# Install resources
	if [ -d "Resources" ]; then \
		mkdir -p $(HOME)/.local/share/sosumi; \
		cp -r Resources/* $(HOME)/.local/share/sosumi/; \
	fi

	@echo "🎉 Installation complete!"
	@echo ""
	@echo "Usage:"
	@echo "  sosumi search \"query\""
	@echo "  /skill sosumi search \"query\""
	@echo ""
	@echo "If sosumi command not found, run: source ~/.zshrc"

# Run tests
test:
	@echo "🧪 Running tests..."
	swift test

# Clean build artifacts
clean:
	@echo "🧹 Cleaning..."
	rm -rf .build
	rm -rf dist

# Create distribution package
dist: build
	@echo "📦 Creating distribution package..."
	mkdir -p dist

	# Copy CLI binary
	cp .build/release/sosumi dist/

	# Copy skill manifest
	cp SKILL.md dist/

	# Copy resources
	if [ -d "Resources" ]; then \
		cp -r Resources dist/; \
	fi

	# Create installation script
	@cat <<'EOF' > dist/install.sh
#!/bin/bash
set -e
SCRIPT_DIR="$$(cd "$$(dirname "$${BASH_SOURCE[0]}")" && pwd)"
echo "🚀 Installing sosumi..."
mkdir -p $$HOME/.local/bin
cp "$$SCRIPT_DIR/sosumi" $$HOME/.local/bin/
mkdir -p $$HOME/.claude/skills
cp "$$SCRIPT_DIR/SKILL.md" $$HOME/.claude/skills/sosumi.md
if [ -d "$$SCRIPT_DIR/Resources" ]; then
    mkdir -p $$HOME/.local/share/sosumi
	cp -r "$$SCRIPT_DIR/Resources"/* $$HOME/.local/share/sosumi/
fi
echo "🎉 Installation complete!"
echo 'Usage: sosumi search "query"'
echo '       /skill sosumi search "query"'
EOF
	chmod +x dist/install.sh

	# Create package
	cd dist && tar -czf sosumi-$(shell git describe --tags --always 2>/dev/null || echo "latest").tar.gz *
	@echo "✅ Distribution package created in dist/"

# Show help
help:
	@echo "sosumi Build System"
	@echo ""
	@echo "Targets:"
	@echo "  build    - Build CLI tool"
	@echo "  install  - Install skill + CLI"
	@echo "  test     - Run tests"
	@echo "  clean    - Clean build artifacts"
	@echo "  dist     - Create distribution package"
	@echo "  help     - Show this help"
	@echo ""
	@echo "Examples:"
	@echo "  make build"
	@echo "  make install"
	@echo "  make dist"
