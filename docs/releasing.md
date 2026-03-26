# Releasing

How to push code changes and publish a new Homebrew release.

## 1. Make Changes

```bash
cd ~/Developer/personal/dev-vm

# Edit code
vim cli/dev

# Test locally
./cli/dev help
./cli/dev status
./cli/dev verify
```

## 2. Commit and Push

```bash
git add -A
git commit -m "Description of changes"
git push origin main
```

## 3. Bump Version

Update the version in `cli/dev`:

```bash
# Line 6 in cli/dev
readonly VERSION="2.2.0"
```

Commit:

```bash
git add cli/dev
git commit -m "Bump to v2.2.0"
git push origin main
```

## 4. Create a Tag

```bash
git tag v2.2.0
git push origin v2.2.0
```

## 5. Get the New SHA

```bash
curl -sL "https://github.com/indranandjha1993/devvm/archive/refs/tags/v2.2.0.tar.gz" | shasum -a 256
```

Copy the hash output.

## 6. Update Homebrew Formula

```bash
cd ~/Developer/personal/homebrew-tap
```

Edit `Formula/devvm.rb` — update **two** fields:

```ruby
url "https://github.com/indranandjha1993/devvm/archive/refs/tags/v2.2.0.tar.gz"
sha256 "PASTE_NEW_SHA_HERE"
```

Commit and push:

```bash
git add Formula/devvm.rb
git commit -m "Update devvm to v2.2.0"
git push origin main
```

## 7. Users Upgrade

```bash
# Users update their local tap and upgrade
brew update
brew upgrade devvm

# Or force reinstall
brew reinstall devvm
```

If `brew update` doesn't pick up the tap change:

```bash
cd /opt/homebrew/Library/Taps/indranandjha1993/homebrew-tap
git pull origin main
brew reinstall devvm
```

## Quick Reference (Copy-Paste)

Replace `X.Y.Z` with your version:

```bash
# In dev-vm repo
vim cli/dev                    # bump VERSION="X.Y.Z"
git add -A && git commit -m "Bump to vX.Y.Z"
git push origin main
git tag vX.Y.Z && git push origin vX.Y.Z

# Get SHA
SHA=$(curl -sL "https://github.com/indranandjha1993/devvm/archive/refs/tags/vX.Y.Z.tar.gz" | shasum -a 256 | awk '{print $1}')
echo $SHA

# In homebrew-tap repo
cd ~/Developer/personal/homebrew-tap
sed -i '' "s|/v[0-9]*\.[0-9]*\.[0-9]*\.tar|/vX.Y.Z.tar|" Formula/devvm.rb
sed -i '' "s/sha256 \".*\"/sha256 \"$SHA\"/" Formula/devvm.rb
git add -A && git commit -m "Update devvm to vX.Y.Z"
git push origin main
```

## File Locations

| What | Path |
|------|------|
| CLI source | `~/Developer/personal/dev-vm/cli/dev` |
| Version line | `cli/dev` line 6: `readonly VERSION="X.Y.Z"` |
| Homebrew formula (source) | `~/Developer/personal/dev-vm/homebrew/devvm.rb` |
| Homebrew formula (tap) | `~/Developer/personal/homebrew-tap/Formula/devvm.rb` |
| Local tap cache | `/opt/homebrew/Library/Taps/indranandjha1993/homebrew-tap/` |
| Installed binary | `/opt/homebrew/bin/devvm` |
