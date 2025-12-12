#!/bin/bash
# Setup script for git security measures

echo "🔐 Setting up Git Security for LangChat"
echo "========================================"
echo ""

# 1. Install pre-commit hook
echo "📋 Step 1: Installing pre-commit hook..."
if [ -f ".git/hooks/pre-commit" ]; then
    echo "   ⚠️  Pre-commit hook already exists. Creating backup..."
    cp .git/hooks/pre-commit .git/hooks/pre-commit.backup
fi

cp scripts/pre-commit-hook.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
echo "   ✅ Pre-commit hook installed"
echo ""

# 2. Check for git-secrets
echo "📋 Step 2: Checking for git-secrets..."
if command -v git-secrets &> /dev/null; then
    echo "   ✅ git-secrets is already installed"
    
    # Initialize git-secrets for this repo
    if git secrets --install 2>/dev/null; then
        echo "   ✅ git-secrets initialized for this repo"
    else
        echo "   ℹ️  git-secrets already initialized"
    fi
    
    # Add custom patterns
    echo "   📝 Adding custom secret patterns..."
    git secrets --add 'sk-or-v1-[a-zA-Z0-9]{48}' 2>/dev/null || true
    git secrets --add 'OPENROUTER_API_KEY\s*=\s*[^[:space:]]+' 2>/dev/null || true
    git secrets --add 'SUPABASE_ANON_KEY\s*=\s*[^[:space:]]+' 2>/dev/null || true
    git secrets --add 'TWILIO_AUTH_TOKEN\s*=\s*[^[:space:]]+' 2>/dev/null || true
    git secrets --add 'sk-[a-zA-Z0-9]{32,}' 2>/dev/null || true
    echo "   ✅ Custom patterns added"
    
    # Scan the repository
    echo "   🔍 Scanning repository for secrets..."
    if git secrets --scan; then
        echo "   ✅ No secrets found in repository"
    else
        echo "   ❌ WARNING: Secrets detected! Review the output above."
    fi
else
    echo "   ⚠️  git-secrets is not installed"
    echo ""
    echo "   To install git-secrets (recommended):"
    echo "   macOS:   brew install git-secrets"
    echo "   Linux:   See https://github.com/awslabs/git-secrets"
    echo ""
    echo "   Then run this script again to configure it."
fi
echo ""

# 3. Verify .gitignore and .gitattributes
echo "📋 Step 3: Verifying security files..."
if [ -f ".gitignore" ]; then
    echo "   ✅ .gitignore exists"
else
    echo "   ❌ ERROR: .gitignore not found!"
fi

if [ -f ".gitattributes" ]; then
    echo "   ✅ .gitattributes exists"
else
    echo "   ⚠️  WARNING: .gitattributes not found"
fi

if [ -f "SECURITY.md" ]; then
    echo "   ✅ SECURITY.md exists"
else
    echo "   ⚠️  WARNING: SECURITY.md not found"
fi
echo ""

# 4. Check for .env files
echo "📋 Step 4: Checking for .env files..."
if [ -f ".env" ]; then
    echo "   ✅ .env file exists (gitignored)"
    if git ls-files --error-unmatch .env 2>/dev/null; then
        echo "   ❌ ERROR: .env is tracked by git! Run: git rm --cached .env"
    fi
else
    echo "   ⚠️  .env file not found. Create one from .env.example"
fi

if [ -f "web-admin/.env.local" ]; then
    echo "   ✅ web-admin/.env.local exists (gitignored)"
    if git ls-files --error-unmatch web-admin/.env.local 2>/dev/null; then
        echo "   ❌ ERROR: web-admin/.env.local is tracked! Run: git rm --cached web-admin/.env.local"
    fi
else
    echo "   ⚠️  web-admin/.env.local not found. Create one from .env.local.example"
fi
echo ""

# 5. Summary
echo "========================================"
echo "✅ Git Security Setup Complete!"
echo ""
echo "Next steps:"
echo "1. Copy .env.example to .env and add your keys"
echo "2. Copy web-admin/.env.local.example to web-admin/.env.local"
echo "3. Never commit files containing secrets"
echo "4. Read SECURITY.md for best practices"
echo ""
echo "Test the pre-commit hook with: git commit"
echo "========================================"
