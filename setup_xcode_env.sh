#!/bin/bash
# Helper script to extract API keys from .env for Xcode environment variables

echo "================================================"
echo "  Xcode Environment Variables Setup Helper"
echo "================================================"
echo ""

if [ ! -f ".env" ]; then
    echo "❌ .env file not found in current directory"
    echo "   Make sure you run this from the project root"
    exit 1
fi

echo "📋 Copy these environment variables to Xcode:"
echo ""
echo "1. In Xcode: Product > Scheme > Edit Scheme"
echo "2. Select 'Run' on the left"
echo "3. Go to 'Arguments' tab"  
echo "4. Under 'Environment Variables', add these:"
echo ""
echo "================================================"

# Extract each key
while IFS='=' read -r key value; do
    # Skip comments and empty lines
    if [[ ! $key =~ ^# ]] && [[ -n $key ]]; then
        # Remove leading/trailing whitespace
        key=$(echo "$key" | xargs)
        value=$(echo "$value" | xargs)
        
        if [[ -n $value ]]; then
            echo "Name:  $key"
            echo "Value: $value"
            echo "---"
        fi
    fi
done < .env

echo "================================================"
echo ""
echo "✅ After adding these, rebuild and run your app!"
