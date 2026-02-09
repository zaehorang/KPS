#!/bin/bash
# Install Git hooks for KPS

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
HOOKS_DIR="$PROJECT_ROOT/.git/hooks"

echo "📦 Installing Git hooks..."

# Copy pre-push hook
cp "$SCRIPT_DIR/hooks/pre-push" "$HOOKS_DIR/pre-push"
chmod +x "$HOOKS_DIR/pre-push"

echo "✅ pre-push hook installed"
echo ""
echo "🔍 This hook will:"
echo "   - Check version consistency when pushing tags"
echo "   - Prevent tag/code version mismatch (e.g., v0.2.0 실수 방지)"
echo ""
echo "✨ Installation complete!"
