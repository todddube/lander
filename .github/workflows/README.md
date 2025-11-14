# GitHub Actions Workflows

This directory contains automated workflows for the Lunar Lander project.

## Workflows

### 1. Build Check (`build.yml`)
**Triggers:**
- On every push to any branch
- On pull requests to main branch

**Purpose:**
- Verifies that the code compiles successfully
- Runs on Windows with MinGW
- Uploads the built executable as an artifact (available for 7 days)

**Use case:** Continuous integration to ensure code quality

---

### 2. Build and Release (`release.yml`)
**Triggers:**
- On push to `main` branch
- On push of tags matching `v*` pattern
- Manual trigger via workflow_dispatch

**Purpose:**
- Builds the executable with CMake
- Reads version from `VERSION` file
- Creates a ZIP archive with executable and documentation
- Creates/updates GitHub releases with the build artifacts
- Automatically tags the release if tag doesn't exist

**What it does:**
1. Checks out the code
2. Reads version from `VERSION` file
3. Sets up MinGW build environment
4. Compiles the game with CMake
5. Packages executable with README, LICENSE, and VERSION
6. Creates a ZIP file: `lander-v{VERSION}-windows.zip`
7. Checks if tag `v{VERSION}` exists
8. If tag doesn't exist:
   - Creates and pushes the tag
   - Creates a new GitHub release with detailed description
   - Uploads the ZIP file
9. If tag exists:
   - Updates the existing release with new build

---

## How to Create a Release

### Method 1: Update VERSION file (Recommended)
1. Edit the `VERSION` file in the root directory
2. Change version number (e.g., `1.0.1`, `1.1.0`, `2.0.0`)
3. Commit and push to main:
   ```bash
   git add VERSION
   git commit -m "Bump version to 1.1.0"
   git push origin main
   ```
4. The workflow automatically creates a tagged release

### Method 2: Manual Tag
1. Create and push a tag manually:
   ```bash
   git tag -a v1.0.1 -m "Release version 1.0.1"
   git push origin v1.0.1
   ```
2. The workflow triggers and creates the release

### Method 3: Manual Trigger
1. Go to GitHub → Actions → "Build and Release"
2. Click "Run workflow"
3. Select branch and click "Run workflow"
4. Uses the version from `VERSION` file

---

## Release Contents

Each release includes:
- **ZIP file** containing:
  - `lander.exe` - The game executable
  - `README.md` - Documentation
  - `LICENSE` - License information
  - `VERSION` - Version number

- **Release notes** with:
  - Version number
  - Feature list
  - How to play instructions
  - Controls
  - System requirements

---

## Version Numbering

Follow semantic versioning (MAJOR.MINOR.PATCH):
- **MAJOR** - Breaking changes or major new features
- **MINOR** - New features, backward compatible
- **PATCH** - Bug fixes and minor improvements

Examples:
- `1.0.0` - Initial release
- `1.0.1` - Bug fix
- `1.1.0` - New feature (high score system)
- `2.0.0` - Major rewrite or breaking changes

---

## Troubleshooting

### Release not created
- Check that `VERSION` file exists and has valid format (e.g., `1.0.0`)
- Verify you have push access to the repository
- Check Actions tab for error messages

### Build fails
- Ensure code compiles locally with `cmake --build build`
- Check for syntax errors or missing files
- Review build logs in Actions tab

### Tag already exists
- Workflow will update the existing release instead
- To create a new release, increment the VERSION number
- Delete the old tag if needed: `git push --delete origin v1.0.0`

---

## Requirements

The workflows use:
- Windows runner (windows-latest)
- MSYS2/MinGW for compilation
- CMake and Ninja for building
- GitHub CLI for release management

No additional setup required - everything is configured in the workflow files.
