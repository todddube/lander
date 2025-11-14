# Quick Release Guide

## Creating a New Release

### Option 1: Bump Version (Easiest) ⭐

1. **Update the version:**
   ```bash
   echo 1.0.1 > VERSION
   ```

2. **Commit and push:**
   ```bash
   git add VERSION
   git commit -m "Bump version to 1.0.1"
   git push origin main
   ```

3. **Done!** GitHub Actions will automatically:
   - Build the executable
   - Create tag `v1.0.1`
   - Create a GitHub release
   - Upload `lander-v1.0.1-windows.zip`

---

### Option 2: Manual Tag

```bash
git tag -a v1.0.1 -m "Release 1.0.1"
git push origin v1.0.1
```

---

### Option 3: Manual Workflow Trigger

1. Go to GitHub → **Actions** tab
2. Select **"Build and Release"** workflow
3. Click **"Run workflow"**
4. Select `main` branch
5. Click **"Run workflow"** button

---

## What Gets Released

Each release includes a ZIP file with:
- ✅ `lander.exe` - The compiled game
- ✅ `README.md` - Documentation
- ✅ `LICENSE` - License file (if exists)
- ✅ `VERSION` - Version number

---

## Version Numbering

Use [Semantic Versioning](https://semver.org/):

```
MAJOR.MINOR.PATCH
```

**Examples:**
- `1.0.0` → `1.0.1` - Bug fix
- `1.0.1` → `1.1.0` - New feature
- `1.1.0` → `2.0.0` - Breaking change

**Current version:** `1.0.0`

---

## Automated Workflows

### 1. Build Check (`build.yml`)
- **Runs on:** Every push and PR
- **Purpose:** Verify code compiles
- **Output:** Build artifact (7 days retention)

### 2. Build and Release (`release.yml`)
- **Runs on:** Push to main, tags, or manual trigger
- **Purpose:** Create releases
- **Output:** Tagged release with ZIP

---

## Troubleshooting

### Release didn't create?
- Check that `VERSION` file exists
- Check Actions tab for errors
- Ensure you pushed to `main` branch

### Tag already exists?
- Workflow will update existing release
- Or increment version number for new release

### Build failed?
- Check build locally: `cmake --build build`
- Review error logs in Actions tab

---

## Quick Commands Reference

```bash
# Check current version
cat VERSION

# Update version
echo "1.0.1" > VERSION

# Commit version change
git add VERSION
git commit -m "Bump version to 1.0.1"
git push

# Create release manually (tag)
git tag -a v1.0.1 -m "Release 1.0.1"
git push origin v1.0.1

# View all tags
git tag -l

# Delete a tag (if needed)
git tag -d v1.0.1
git push --delete origin v1.0.1
```

---

## Release Checklist

Before releasing:
- [ ] Test the game locally
- [ ] Update version in `VERSION` file
- [ ] Update `CHANGELOG.md` (if you have one)
- [ ] Review README for accuracy
- [ ] Commit all changes
- [ ] Push to main or create tag
- [ ] Monitor Actions tab for build
- [ ] Verify release on GitHub
- [ ] Download and test release ZIP

---

## Where to Find Releases

**On GitHub:**
1. Go to your repository
2. Click **"Releases"** (right sidebar)
3. See all versions listed

**Direct URL format:**
```
https://github.com/todddube/lander/releases
```

---

**That's it!** The GitHub Actions do all the heavy lifting. 🚀
