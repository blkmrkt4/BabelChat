# Security Setup Guide

## ✅ Credential Management (FIXED)

Your Supabase credentials are now properly secured using environment variables instead of hardcoded values.

### How It Works

1. **Config.swift** loads credentials from environment variables
2. **SupabaseService.swift** uses Config.swift (no hardcoded keys)
3. **SupabaseConfig.swift** is NOT tracked in git (.gitignore)

### Setup Instructions

You have **two options** to provide credentials:

#### Option 1: Xcode Environment Variables (Recommended)

1. In Xcode, go to **Product → Scheme → Edit Scheme**
2. Select **Run** on the left sidebar
3. Go to **Arguments** tab
4. Under **Environment Variables**, add:
   - `SUPABASE_URL` = `https://ckhukylfoeofvoxvwwin.supabase.co`
   - `SUPABASE_ANON_KEY` = `your-anon-key-here`
   - `OPENROUTER_API_KEY` = `your-openrouter-key-here`

#### Option 2: .env File (Alternative)

1. Copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` and fill in your actual values:
   ```bash
   SUPABASE_URL=https://ckhukylfoeofvoxvwwin.supabase.co
   SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
   OPENROUTER_API_KEY=sk-or-v1-...
   ```

3. **NEVER commit .env to git** (it's already in .gitignore)

### ⚠️ IMPORTANT: Rotate Your Supabase API Key

Since your old Supabase key was committed to git history, you should **rotate it**:

1. Go to https://supabase.com/dashboard
2. Select your project: `ckhukylfoeofvoxvwwin`
3. Go to **Settings → API**
4. Click **Reset API Key** (or generate a new project)
5. Update your environment variables with the new key

**Why?** Even though we removed the key from the code, it's still visible in git history. Anyone with access to your repo can see the old commits.

### Verification

Run the app and check the console. You should see:
```
✅ Supabase initialized: https://ckhukylfoeofvoxvwwin.supabase.co
```

If you see an error like `❌ SUPABASE_URL not found!`, your environment variables aren't set up correctly.

### Files Updated

- ✅ `SupabaseService.swift` - Now uses Config.swift
- ✅ `SupabaseTestViewController.swift` - Updated debug checks
- ✅ `.gitignore` - Already blocking SupabaseConfig.swift
- ✅ `.env.example` - Template for other developers

### Security Best Practices

1. ✅ **Never hardcode credentials** in source code
2. ✅ **Use environment variables** for all API keys
3. ✅ **Add sensitive files to .gitignore** BEFORE committing them
4. ✅ **Rotate keys** if they're ever exposed
5. ✅ **Use Supabase Row Level Security (RLS)** for database protection
6. ⚠️ **TODO:** Implement certificate pinning for API requests
7. ⚠️ **TODO:** Enable Supabase audit logs for monitoring

### Next Steps

1. **Set up environment variables** using Option 1 or 2 above
2. **Rotate your Supabase API key** in the dashboard
3. **Test the app** to confirm it still connects
4. **Commit this security fix** to git

### If You Need Help

- Xcode scheme documentation: https://developer.apple.com/documentation/xcode/customizing-the-build-schemes-for-a-project
- Supabase security docs: https://supabase.com/docs/guides/auth/row-level-security
