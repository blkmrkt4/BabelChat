# Security Guidelines for LangChat

## API Key Management

### ⚠️ Critical Security Rules

1. **NEVER commit API keys to git**
   - API keys must never appear in source code
   - Use `.env` files for local development (already in `.gitignore`)
   - Production apps should use secure backend services

2. **What happened with the exposed key**
   - The OpenRouter API key was hardcoded in `Config.swift` line 12
   - This file was committed to GitHub on October 26, 2024
   - OpenRouter detected the exposed key and disabled it automatically
   - Exposed keys can be used by anyone to make API calls at your expense

## Setting Up Your Development Environment

### Step 1: Get Your API Keys

1. **OpenRouter**: Visit https://openrouter.ai/keys
   - Create a new API key
   - Set spending limits to prevent unexpected charges
   - Never reuse a key that has been exposed

2. **Supabase**: Visit https://supabase.com/dashboard/project/_/settings/api
   - Copy your project URL
   - Copy your anon/public key

### Step 2: Create Your .env File

```bash
# In the project root directory
cp .env.example .env
```

Then edit `.env` with your actual keys:

```bash
OPENROUTER_API_KEY=sk-or-v1-your-actual-key-here
SUPABASE_URL=https://yourproject.supabase.co
SUPABASE_ANON_KEY=your-actual-anon-key-here
```

### Step 3: Verify .env is Ignored

The `.env` file should already be in `.gitignore`. Verify with:

```bash
git check-ignore .env
```

This should output: `.env` (confirming it's ignored)

## How Config.swift Works

The `Config.swift` file now **requires** all API keys to be present in the `.env` file:

```swift
// If the key is missing, the app will crash with a helpful error message
// This prevents accidentally running with missing configuration
static let openRouterAPIKey: String = {
    guard let envKey = readEnvFile(key: "OPENROUTER_API_KEY") else {
        fatalError("OPENROUTER_API_KEY not found in .env file!")
    }
    return envKey
}()
```

## Best Practices for iOS Apps

### For Development (Current Setup)
✅ Use `.env` files (never committed)
✅ Clear error messages when keys are missing
✅ `.gitignore` prevents accidental commits

### For Production (Future Implementation)

When releasing to the App Store, consider these additional security measures:

1. **Backend Proxy Service**
   ```
   iOS App → Your Backend → OpenRouter API
   ```
   - Your backend holds the API key
   - iOS app only talks to your backend
   - Prevents key extraction from app bundle

2. **Key Rotation**
   - Rotate API keys regularly
   - Use different keys for development/production
   - Monitor usage for anomalies

3. **Rate Limiting**
   - Implement per-user limits
   - Prevent abuse if authentication is bypassed

4. **Secure Storage**
   - If you must store keys locally, use iOS Keychain
   - Never use UserDefaults or plain files
   - Example: `KeychainService.save(key: "api_key", value: apiKey)`

## If Your Key is Exposed

If you accidentally commit a key:

1. **Immediately revoke the key** at the service provider
2. **Generate a new key**
3. **Remove from git history** (see below)
4. **Update your local .env** with the new key

### Removing Secrets from Git History

```bash
# WARNING: This rewrites git history. Coordinate with your team!

# Option 1: Use BFG Repo-Cleaner (recommended)
brew install bfg
bfg --replace-text passwords.txt  # List of secrets to remove
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# Option 2: Use git-filter-repo
brew install git-filter-repo
git filter-repo --invert-paths --path LangChat/Core/Config.swift

# Option 3: Force push a new clean commit (last resort)
git commit --amend -m "Remove exposed API keys"
git push --force
```

⚠️ **After removing the secret**: Contact the service provider to confirm the key is disabled.

## Monitoring and Auditing

1. **Check OpenRouter Dashboard** regularly
   - Monitor usage and spending
   - Set up billing alerts
   - Review access logs

2. **GitHub Security**
   - Enable secret scanning in repository settings
   - Set up Dependabot alerts
   - Review access permissions

3. **Code Reviews**
   - Never approve PRs with hardcoded secrets
   - Use automated tools (e.g., `git-secrets`, `truffleHog`)

## Questions?

- OpenRouter Security: security@openrouter.ai
- GitHub Secret Scanning: https://docs.github.com/en/code-security/secret-scanning
- iOS Keychain Services: https://developer.apple.com/documentation/security/keychain_services

## Additional Resources

- [OWASP Mobile Security](https://owasp.org/www-project-mobile-security/)
- [iOS Security Guide](https://support.apple.com/guide/security/welcome/web)
- [Supabase Security Best Practices](https://supabase.com/docs/guides/platform/security)
