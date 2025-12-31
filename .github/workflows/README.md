# GitHub Actions Workflows

Automated CI/CD for the Lunar Lander project.

## Workflows

### Build Check (`build.yml`)

**Triggers:** Every push and pull request

**Purpose:** Verifies the code compiles successfully with MinGW/CMake.

### Build and Release (`release.yml`)

**Triggers:** Push to `main`, version tags (`v*`), or manual dispatch

**Purpose:** Builds the game and creates GitHub releases automatically.

**What it does:**
1. Reads version from `VERSION` file
2. Builds with CMake/MinGW
3. Creates ZIP with `lander.exe`, `README.md`, `LICENSE`, `VERSION`
4. Creates/updates Git tag `v{VERSION}`
5. Creates/updates GitHub release with release notes

---

## Creating a Release

### Recommended: Update VERSION file

```bash
echo 1.0.1 > VERSION
git add VERSION
git commit -m "Bump version to 1.0.1"
git push
```

The workflow automatically:
- Creates tag `v1.0.1`
- Creates GitHub release
- Uploads `lander-v1.0.1-windows.zip`

### Alternative: Manual tag

```bash
git tag -a v1.0.1 -m "Release 1.0.1"
git push origin v1.0.1
```

### Alternative: Manual trigger

1. Go to Actions → "Build and Release"
2. Click "Run workflow"
3. Select branch, click "Run workflow"

---

## Release Contents

Each release ZIP includes:
- `lander.exe` - The game
- `README.md` - Documentation
- `LICENSE` - License file
- `VERSION` - Version number

---

## Version Numbering

Use semantic versioning: `MAJOR.MINOR.PATCH`

- `1.0.0` → `1.0.1` - Bug fix
- `1.0.1` → `1.1.0` - New feature
- `1.1.0` → `2.0.0` - Breaking change

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Release not created | Check `VERSION` file exists and has valid format |
| Tag already exists | Workflow updates existing release, or increment version |
| Build failed | Check Actions tab for error logs |
