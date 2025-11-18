# Contributing to sosumi

Thank you for your interest in contributing to sosumi! This guide will help you get started.

## 🚀 Getting Started

### Prerequisites
- macOS 13.0+ (Ventura)
- Swift 5.7+
- Xcode 14+ (optional, for development)

### Setup
```bash
# Clone the repository
git clone https://github.com/Smith-Tools/sosumi.git
cd sosumi

# Build the project
swift build

# Run tests
swift test

# Install locally
make install
```

## 📁 Project Structure

```
sosumi/
├── Sources/
│   ├── SosumiCLI/         ← Command-line interface
│   ├── SosumiCore/        ← Core functionality
│   └── Skill/             ← Claude Code skill components
│       └── SKILL.md       ← Skill manifest
├── Scripts/               ← Build and utility scripts
├── docs/                  ← Documentation
├── Package.swift          ← Swift package configuration
├── Makefile               ← Build and installation targets
└── Tests/                 ← Test suites
```

## 🧪 Testing

### Running Tests
```bash
# Run all tests
swift test

# Run specific test
swift test --filter testSearchFunctionality

# Run tests with verbose output
swift test --verbose
```

### Adding Tests
- Add new tests to `Tests/` directory
- Follow existing naming conventions
- Test both success and failure cases
- Include performance tests for search functionality

## 🐛 Bug Reports

### Before Creating a Bug Report
1. Check existing issues
2. Ensure you're using the latest version
3. Try to reproduce the issue with minimal code

### Bug Report Template
```markdown
## Description
Brief description of the issue

## Steps to Reproduce
1. Step 1
2. Step 2
3. Step 3

## Expected Behavior
What should happen

## Actual Behavior
What actually happens

## Environment
- macOS version:
- Swift version:
- sosumi version:
```

## 💡 Feature Requests

### Proposing Features
1. Open an issue with "Feature Request" label
2. Describe the use case and benefits
3. Consider implementation complexity
4. Discuss breaking changes

### Feature Request Template
```markdown
## Feature Description
Clear description of the feature

## Use Case
Why is this feature needed?

## Benefits
What problems does it solve?

## Implementation Ideas (Optional)
Any thoughts on how to implement
```

## 🔧 Development Guidelines

### Code Style
- Follow Swift style guidelines
- Use meaningful variable and function names
- Add comments for complex logic
- Include documentation for public APIs

### Commit Messages
- Use conventional commit format
- Start with a verb (feat:, fix:, docs:, etc.)
- Keep first line under 50 characters
- Add detailed description if needed

Example:
```
feat(search): add relevance scoring to search results

Implements TF-IDF scoring algorithm to provide more relevant
search results based on query term frequency and importance.

- Add TF-IDF calculation utilities
- Update search ranking logic
- Add performance benchmarks
```

### Pull Request Process
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request with:
   - Clear description of changes
   - Links to related issues
   - Testing instructions
   - Screenshots if applicable

## 📊 Performance Considerations

### Search Performance
- Aim for sub-10ms search responses
- Minimize memory usage for large datasets
- Consider caching frequently accessed data
- Profile changes before submitting

### Memory Usage
- Be mindful of memory consumption with large datasets
- Use streaming for large file operations
- Clean up resources properly
- Profile memory usage in development

## 🔒 Security

### Important Security Note
This project works with obfuscated data that has been processed through a private pipeline. When contributing:

- **DO NOT** attempt to reverse engineer data sources
- **DO NOT** add code that could expose sensitive information
- **DO NOT** commit any raw or decrypted data
- **DO** focus on tool functionality and user experience
- **DO** report any security concerns privately

### Security Reporting
If you discover a security vulnerability:
1. **DO NOT** open a public issue
2. Email the maintainers privately
3. Include detailed reproduction steps
4. Allow time for investigation before disclosure

## 📖 Documentation

### Improving Documentation
- Fix typos and grammatical errors
- Add examples for complex features
- Improve README clarity
- Add API documentation for new functions

### Documentation Style
- Use clear, concise language
- Include code examples
- Add screenshots where helpful
- Keep documentation up-to-date with code changes

## 🤝 Community Guidelines

### Code of Conduct
- Be respectful and inclusive
- Welcome newcomers and help them learn
- Focus on constructive feedback
- Assume good intentions

### Getting Help
- Search existing issues and discussions
- Ask questions in GitHub Discussions
- Join the Smith Tools community channels
- Be patient with volunteer maintainers

## 🏆 Recognition

Contributors are recognized in:
- README.md contributors section
- Release notes for significant contributions
- GitHub contributor statistics
- Community spotlights

Thank you for contributing to sosumi and the Smith Tools ecosystem! 🎉