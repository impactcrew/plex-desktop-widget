# Contributing to Plex Desktop Widget

Thank you for your interest in contributing to the Plex Desktop Widget! We welcome contributions from the community, whether it's bug reports, feature requests, documentation improvements, or code contributions.

This guide will help you understand our development process and how to contribute effectively.

---

## Code of Conduct

By participating in this project, you agree to maintain a respectful and inclusive environment for all contributors. We're committed to providing a welcoming space for everyone.

---

## How to Contribute

### Reporting Bugs

Found a bug? We'd love to hear about it! Before creating a bug report, please:

1. **Check the [existing issues](../../issues)** to see if the bug has already been reported
2. **Check the [FAQ and Troubleshooting section](README.md#troubleshooting)** in the README
3. **Gather information** about your system and the steps to reproduce the issue

When you're ready, [create a new issue](../../issues/new/choose) using the **Bug Report** template. Include:

- **Description**: Clear, concise summary of the bug
- **macOS Version**: Output of `sw_vers` or from System Settings
- **System Architecture**: Intel or Apple Silicon (check with `uname -m`)
- **Plex Server Type**: Plex Media Server version and type
- **Steps to Reproduce**: Detailed steps that trigger the bug
- **Expected Behavior**: What should happen
- **Actual Behavior**: What actually happens
- **Screenshots**: If applicable
- **Logs**: Any relevant error messages or system logs

### Requesting Features

Have an idea for a new feature? We'd like to hear it!

1. **Check existing issues** to see if the feature has been requested
2. [Create a new issue](../../issues/new/choose) using the **Feature Request** template
3. **Describe your use case** and why you think this feature would be valuable

When filing a feature request, include:

- **Feature Description**: Clear explanation of the feature
- **Motivation**: Why do you need this feature?
- **Use Case**: Specific scenario where this would be helpful
- **Proposed Implementation**: Optional suggestions on how to implement it
- **Alternatives**: Any workarounds or alternative approaches

### Improving Documentation

Documentation improvements are always welcome! You can:

1. **Improve clarity**: Fix confusing sections or examples
2. **Add examples**: Contribute real-world usage examples
3. **Fix typos**: Correct spelling or grammatical errors
4. **Expand guides**: Add detailed explanations for complex topics
5. **Translate**: Help translate documentation to other languages

To contribute documentation:

1. Fork the repository
2. Edit the relevant `.md` files
3. Test your changes locally (see [Building from Source](README.md#building-from-source))
4. Submit a pull request with a clear description of changes

---

## Code Contributions

### Development Environment Setup

Before starting development, set up your local environment:

#### Prerequisites

- **Xcode 14.0 or later**
- **Swift 5.8 or later**
- **Git**
- **macOS 13.0 or later**

#### Initial Setup

1. **Fork the repository** on GitHub
2. **Clone your fork**:
   ```bash
   git clone https://github.com/YOUR_USERNAME/plex-desktop-widget.git
   cd plex-desktop-widget
   ```

3. **Add upstream remote** (to sync with original):
   ```bash
   git remote add upstream https://github.com/ORIGINAL_OWNER/plex-desktop-widget.git
   ```

4. **Open in Xcode**:
   ```bash
   open PlexWidget/PlexWidget.xcodeproj
   ```

### Development Workflow

#### 1. Create a Feature Branch

Always create a new branch for your work:

```bash
# Sync with latest upstream
git fetch upstream
git rebase upstream/main

# Create feature branch with descriptive name
git checkout -b feature/your-feature-name
# or for bug fixes:
git checkout -b fix/bug-description
```

**Branch naming conventions**:
- `feature/description` - For new features
- `fix/bug-description` - For bug fixes
- `docs/improvement-description` - For documentation
- `refactor/change-description` - For refactoring

#### 2. Make Your Changes

Write your code following our style guide (see below). Commit often with clear messages:

```bash
git add .
git commit -m "Clear description of changes (present tense)"
```

**Commit message guidelines**:
- Use present tense ("add feature" not "added feature")
- Be concise but descriptive
- Reference issues when relevant: "fix: resolve crash when no connection (#123)"
- Format: `type: description` where type is: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

Example commits:
```
feat: add support for multiple playback sessions
fix: resolve crash when plex token is invalid
docs: improve installation instructions
refactor: simplify network request handling
```

#### 3. Test Your Changes

Before submitting, thoroughly test your changes:

1. **Build the application**:
   ```bash
   xcodebuild -scheme PlexWidget -configuration Debug
   ```

2. **Run the app** and verify functionality:
   - Test with your local Plex server
   - Test with remote Plex server
   - Verify playback controls work correctly
   - Check UI responsiveness and layout

3. **Test edge cases**:
   - No Plex server available
   - Invalid authentication token
   - Network disconnection
   - Long track names and artist names
   - Rapid control clicks

4. **Verify on both architectures** (if possible):
   - Intel Mac
   - Apple Silicon Mac

### Code Style Guide

#### Swift Code Style

We follow the [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/) and [Google's Swift Style Guide](https://google.github.io/swift/).

**Key principles**:

1. **Naming**:
   - Use clear, pronounceable names
   - Use `camelCase` for variables and functions
   - Use `PascalCase` for types and classes
   - Avoid abbreviations unless universally understood
   - Use full words instead of acronyms when possible

2. **Formatting**:
   - Use 4-space indentation (not tabs)
   - Limit lines to a reasonable length (typically 100 characters)
   - One blank line between logical sections
   - Two blank lines between class/struct definitions

3. **SwiftUI Views**:
   - Keep views small and focused
   - Extract complex views into separate components
   - Use proper state management (State, StateObject, EnvironmentObject)
   - Prefer composition over inheritance

4. **Comments**:
   - Write comments that explain *why*, not *what*
   - Use documentation comments (`///`) for public APIs
   - Keep comments up-to-date with code changes

#### Example Code Style

```swift
/// Fetches the current playback status from Plex server
/// - Parameter completion: Callback with the status or error
func fetchPlaybackStatus(completion: @escaping (Result<PlaybackStatus, Error>) -> Void) {
    guard let serverURL = Configuration.shared.serverURL else {
        completion(.failure(PlexError.missingConfiguration))
        return
    }

    let url = serverURL.appendingPathComponent("status/sessions")

    URLSession.shared.dataTask(with: url) { data, response, error in
        if let error = error {
            completion(.failure(error))
            return
        }

        guard let data = data else {
            completion(.failure(PlexError.invalidResponse))
            return
        }

        do {
            let status = try JSONDecoder().decode(PlaybackStatus.self, from: data)
            completion(.success(status))
        } catch {
            completion(.failure(PlexError.decodingError(error)))
        }
    }.resume()
}
```

#### Architecture Guidelines

- **MVVM Pattern**: Use Model-View-ViewModel pattern for separation of concerns
- **Dependency Injection**: Pass dependencies explicitly rather than using globals
- **Error Handling**: Use Swift's `Result` type and proper error handling
- **Networking**: Use URLSession with proper error handling and cancellation
- **State Management**: Use SwiftUI's state management tools appropriately

### Testing

While formal unit tests aren't required for all contributions, please test:

1. **Functionality**: Ensure your changes work as intended
2. **Edge Cases**: Test with invalid inputs and error conditions
3. **UI**: Check layout and behavior across screen sizes
4. **Integration**: Test with actual Plex server if applicable

### Documentation in Code

Help future maintainers by documenting complex logic:

```swift
/// Handles playback control commands sent to the Plex server
/// - Note: Uses MediaRemote framework for system integration
/// - Parameters:
///   - command: The control command (play, pause, next, previous)
/// - Returns: True if command was successfully sent
func sendPlaybackCommand(_ command: PlaybackCommand) -> Bool {
    // Implementation details...
}
```

---

## Submitting Changes

### Pull Request Process

1. **Keep it focused**: One feature or fix per pull request
2. **Test locally**: Ensure all tests pass and functionality works
3. **Rebase if needed**: Keep commits clean and linear
4. **Create the PR**:
   - Use a descriptive title
   - Reference related issues
   - Provide context about your changes

#### Pull Request Template

When you create a PR, use this template:

```markdown
## Description
Brief description of what this PR does.

## Type of Change
- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to change)
- [ ] Documentation update

## Related Issues
Closes #(issue number)

## Changes Made
- List specific changes
- Include implementation details if complex
- Reference code locations if helpful

## Testing
- [ ] Tested on Intel Mac
- [ ] Tested on Apple Silicon Mac
- [ ] Tested with local Plex server
- [ ] Tested with remote Plex server
- [ ] Tested edge cases

## Screenshots
If applicable, add screenshots showing the changes.

## Checklist
- [ ] My code follows the code style guidelines
- [ ] I have updated documentation as needed
- [ ] I have tested the changes thoroughly
- [ ] No new warnings are generated
- [ ] Changes are backward compatible
```

### Code Review Process

1. **Initial Review**: A maintainer will review your PR for:
   - Code quality and style compliance
   - Adherence to project guidelines
   - Test coverage
   - Documentation

2. **Feedback**: You may receive feedback on:
   - Code improvements
   - Additional testing needs
   - Documentation updates
   - Performance considerations

3. **Revisions**: Make requested changes and push updates to your branch
4. **Approval**: Once approved, a maintainer will merge your PR

### After Merge

- Your PR will be included in the next release
- You'll be credited in the changelog
- Thank you for contributing!

---

## Project Structure

Understanding the project structure will help you navigate the codebase:

```
plex-desktop-widget/
├── PlexWidget/                 # Main Swift project
│   ├── PlexWidget.xcodeproj   # Xcode project file
│   └── Sources/
│       ├── App.swift           # Application entry point
│       ├── Models/             # Data models
│       │   ├── PlaybackStatus.swift
│       │   └── MediaItem.swift
│       ├── Views/              # SwiftUI views
│       │   ├── ContentView.swift
│       │   ├── WidgetView.swift
│       │   └── SettingsView.swift
│       ├── Services/           # Business logic
│       │   ├── PlexAPIService.swift
│       │   ├── ConfigurationManager.swift
│       │   └── MediaControlService.swift
│       └── Utilities/          # Helper functions
│           ├── Extensions.swift
│           └── Constants.swift
├── README.md                   # Main documentation
├── CONTRIBUTING.md             # This file
├── .github/
│   ├── ISSUE_TEMPLATE/        # Issue templates
│   └── workflows/              # CI/CD workflows (if any)
└── .gitignore                  # Git ignore rules
```

---

## Common Tasks

### Adding a New Feature

1. Create a feature branch
2. Add models in `Models/` if needed
3. Implement business logic in `Services/`
4. Create or update views in `Views/`
5. Write clear commit messages
6. Submit a PR with description

### Fixing a Bug

1. Create a fix branch
2. Write a test case that reproduces the bug (if applicable)
3. Fix the bug in the relevant file
4. Test the fix thoroughly
5. Submit a PR referencing the issue

### Improving Documentation

1. Create a docs branch
2. Edit the relevant `.md` files
3. Build locally and preview if possible
4. Submit a PR with improvements

---

## Getting Help

If you're stuck or have questions:

1. **Check the documentation**: Read [README.md](README.md) and related guides
2. **Search existing issues**: Look for similar problems
3. **Ask in discussions**: Start a [GitHub discussion](../../discussions)
4. **Comment on issues**: Ask for clarification on specific issues
5. **Contact maintainers**: Reach out to the project maintainers

---

## Recognition

Contributors will be recognized in:

- **Release notes**: Listed as contributors in each release
- **Contributors page**: Visible in the GitHub contributors graph
- **README**: Acknowledged in the project README (for significant contributions)

---

## License

By contributing to this project, you agree that your contributions will be licensed under the MIT License.

---

## Questions?

If you have questions about the contribution process or guidelines, please:

1. Check this guide thoroughly
2. Review the [README.md](README.md)
3. Search [existing issues and discussions](../../issues)
4. [Create a new discussion](../../discussions) with your question

We appreciate your interest in improving Plex Desktop Widget!

---

**Last Updated**: November 2024
**Version**: 2.0.0
