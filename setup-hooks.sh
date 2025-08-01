#!/bin/bash

echo "Setting up Git hooks..."

if [ -d ".git" ]; then
    echo "📁 Configuring Git hooks directory..."
    git config core.hooksPath .githooks
    echo "✅ Git hooks configured!"
    echo ""
    echo "Pre-commit hook will now run:"
    echo "  🧪 All tests (unit + integration)"
    echo "  🔍 Shellcheck linting"
    echo "  🔍 YAML validation"
    echo ""
    echo "To skip hooks temporarily: git commit --no-verify"
else
    echo "❌ Not a Git repository. Run this script from the repository root."
    exit 1
fi
