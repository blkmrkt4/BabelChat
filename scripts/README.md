# Security Scripts

This directory contains security scripts to prevent API keys and secrets from being committed to git.

## Files

### `pre-commit-hook.sh`
Pre-commit hook that scans for secrets before allowing a commit.

**Automatically blocks:**
- `.env` and `.env.*` files
- Files containing API key patterns
- JWT tokens
- AWS keys
- Google API keys
- Passwords and secrets

**Installation:**
```bash
./scripts/setup-git-security.sh
```

Or manually:
```bash
cp scripts/pre-commit-hook.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

### `setup-git-security.sh`
One-command setup for all security measures.

**What it does:**
1. Installs pre-commit hook
2. Configures git-secrets (if installed)
3. Verifies .gitignore and .gitattributes
4. Checks for .env files
5. Scans repository for existing secrets

**Usage:**
```bash
./scripts/setup-git-security.sh
```

## Testing

Test the pre-commit hook by trying to commit a file with a fake API key:

```bash
# Create a test file with a fake secret
echo "OPENROUTER_API_KEY=sk-or-v1-test123" > test.txt
git add test.txt
git commit -m "test"
# Should be blocked by pre-commit hook
rm test.txt
```

## Bypassing the Hook (Not Recommended)

Only in emergencies (like when the hook has false positives):

```bash
git commit --no-verify -m "emergency commit"
```

**Note:** This should be avoided. Instead, fix the issue or update the hook patterns.

## Additional Protection: git-secrets

For maximum security, install git-secrets:

```bash
# macOS
brew install git-secrets

# Run setup again
./scripts/setup-git-security.sh
```

## See Also

- [SECURITY.md](../SECURITY.md) - Complete security policy and best practices
- [.gitignore](../.gitignore) - Files automatically ignored by git
- [.gitattributes](../.gitattributes) - Additional git security rules
