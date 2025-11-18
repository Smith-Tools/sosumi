# Homebrew formula for sosumi
# Template for Smith-Tools/homebrew-smith tap

class Sosumi < Formula
  desc "Apple Documentation & WWDC Skill (Hybrid: Claude Skill + CLI Tool)"
  homepage "https://github.com/Smith-Tools/sosumi"
  url "https://github.com/Smith-Tools/sosumi.git",
      tag: "v1.0.0",
      revision: "abc123def456"  # This will be updated by CI

  head "https://github.com/Smith-Tools/sosumi.git", branch: "main"

  depends_on :macos => :ventura  # macOS 13.0+

  def install
    # Build the CLI tool
    system "swift", "build", "-c", "release", "--disable-sandbox"

    # Install CLI binary
    bin.install ".build/release/sosumi"

    # Install Claude skill manifest only
    mkdir_p "#{HOMEBREW_PREFIX}/share/claude/skills"
    cp "Sources/Skill/SKILL.md", "#{HOMEBREW_PREFIX}/share/claude/skills/sosumi.md"

    # Install resources (obfuscated data only)
    if File.exist?("Resources")
      pkgshare.install "Resources"
    end

    # Create cache directory
    mkdir_p "#{HOMEBREW_PREFIX}/var/cache/sosumi"
  end

  def caveats
    <<~EOS
      sosumi provides both a CLI tool and a Claude Code skill.

      CLI Usage:
        sosumi search "query"              # Search Apple docs
        sosumi wwdc "topic"                # Search WWDC sessions
        sosumi performance                 # Show cache stats

      Claude Skill Usage:
        /skill sosumi search "query"       # Same functionality in Claude
        /skill sosumi wwdc "topic"
        /skill sosumi shareplay            # Specialized SharePlay search

      Both components share the same cache for optimal performance.

      To uninstall completely:
        brew uninstall sosumi
        rm -rf #{HOMEBREW_PREFIX}/var/cache/sosumi
    EOS
  end

  test do
    # Test CLI tool
    system "#{bin}/sosumi", "--version"

    # Test skill manifest exists
    assert_predicate "#{HOMEBREW_PREFIX}/share/claude/skills/sosumi.md", :exist?

    # Test basic functionality (would require network access)
    # system "#{bin}/sosumi", "search", "test", "--limit", "1"
  end

  service do
    run [opt_bin/"sosumi", "daemon"]
    environment_variables PATH: std_service_path_env
    keep_alive true
    log_path var/"log/sosumi.log"
    error_log_path var/"log/sosumi.error.log"
  end
end