#!/bin/bash
# Pre-commit hook to prevent committing secrets and API keys

echo "🔍 Scanning for secrets and API keys..."

# Define patterns to search for
PATTERNS=(
    'sk-or-v1-[a-zA-Z0-9]{48}'                    # OpenRouter API keys
    'sk-[a-zA-Z0-9]{32,}'                         # Generic API keys
    'OPENROUTER_API_KEY\s*=\s*["\047][^"\047]+'   # OpenRouter in files
    'SUPABASE_ANON_KEY\s*=\s*["\047][^"\047]+'    # Supabase anon key
    'TWILIO_AUTH_TOKEN\s*=\s*["\047][^"\047]+'    # Twilio auth token
    'eyJ[a-zA-Z0-9_-]{10,}\.[a-zA-Z0-9_-]{10,}'   # JWT tokens
    'AKIA[0-9A-Z]{16}'                             # AWS access keys
    'AIza[0-9A-Za-z-_]{35}'                        # Google API keys
    'password\s*=\s*["\047][^"\047]{3,}'           # Passwords
    'secret\s*=\s*["\047][^"\047]{3,}'             # Secrets
)

# Files to always block
BLOCKED_FILES=(
    '.env'
    '.env.local'
    '.env.production'
    '.env.development'
    '.mcp.json'
    '.claude.json'
    'secrets.json'
)

# Get list of staged files
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM)

# Check if any blocked files are being committed
for BLOCKED_FILE in "${BLOCKED_FILES[@]}"; do
    if echo "$STAGED_FILES" | grep -q "^$BLOCKED_FILE$\|/$BLOCKED_FILE$"; then
        echo "❌ ERROR: Attempting to commit blocked file: $BLOCKED_FILE"
        echo "   This file should NEVER be committed to git."
        echo "   Remove it from staging with: git reset HEAD $BLOCKED_FILE"
        exit 1
    fi
done

# Check file content for secret patterns
FOUND_SECRET=0
for FILE in $STAGED_FILES; do
    # Skip binary files and large files
    if [ ! -f "$FILE" ] || file "$FILE" | grep -q "binary"; then
        continue
    fi
    
    # Skip files in .gitignore (double check)
    if git check-ignore -q "$FILE"; then
        echo "⚠️  WARNING: $FILE is in .gitignore but staged. This shouldn't happen!"
        continue
    fi
    
    # Scan for each pattern
    for PATTERN in "${PATTERNS[@]}"; do
        if grep -qiE "$PATTERN" "$FILE" 2>/dev/null; then
            echo "❌ ERROR: Potential secret found in $FILE"
            echo "   Pattern matched: $PATTERN"
            echo "   Please remove the secret before committing."
            FOUND_SECRET=1
        fi
    done
    
    # Check for .env-like content in non-.env files
    if [[ ! "$FILE" =~ \.env\.example$ ]] && grep -qE '^[A-Z_]+_API_KEY\s*=' "$FILE" 2>/dev/null; then
        echo "⚠️  WARNING: $FILE contains environment variable assignments"
        echo "   Make sure these are not actual secrets."
    fi
done

if [ $FOUND_SECRET -eq 1 ]; then
    echo ""
    echo "❌ COMMIT REJECTED: Secrets detected"
    echo ""
    echo "What to do:"
    echo "1. Remove the secrets from your code"
    echo "2. Use environment variables instead"
    echo "3. Update .env file (which is gitignored)"
    echo "4. See SECURITY.md for proper secret management"
    echo ""
    exit 1
fi

echo "✅ No secrets detected. Proceeding with commit."
exit 0
