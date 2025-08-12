#!/bin/bash

# Claude Config Setup Script
# Sets up CLAUDE.md and project structure for new projects

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${1:-$(pwd)}"
WIZARD_MODE=false

# Check for --wizard flag in any position
for arg in "$@"; do
    if [ "$arg" = "--wizard" ]; then
        WIZARD_MODE=true
        break
    fi
done

# Remove --wizard from TARGET_DIR if it was passed as first argument
if [ "$1" = "--wizard" ]; then
    TARGET_DIR="${2:-$(pwd)}"
fi

echo "🤖 Claude Config Setup"
echo "Setting up Claude configuration in: $TARGET_DIR"

# Create target directory if it doesn't exist
mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR"

# Copy CLAUDE.md template
if [ ! -f "CLAUDE.md" ]; then
    echo "📝 Creating CLAUDE.md..."
    cp "$SCRIPT_DIR/CLAUDE_TEMPLATE.md" "CLAUDE.md"
    echo "✅ CLAUDE.md created"
else
    echo "⚠️  CLAUDE.md already exists, skipping..."
fi

# Copy PROJECT.md template if it doesn't exist
if [ ! -f "PROJECT.md" ]; then
    echo "📋 Creating PROJECT.md template..."
    cp "$SCRIPT_DIR/PROJECT.md" "PROJECT.md"
    echo "✅ PROJECT.md template created"
else
    echo "⚠️  PROJECT.md already exists, skipping..."
fi

# Create .agent_projects directory structure
echo "📁 Setting up .agent_projects structure..."
mkdir -p ".agent_projects"

# Copy template files
if [ ! -d ".agent_projects/_template" ]; then
    cp -r "$SCRIPT_DIR/agent_projects/_template" ".agent_projects/_template"
    echo "✅ Project template structure created"
else
    echo "⚠️  Template directory already exists, skipping..."
fi

# Copy CONVENTIONS.md and remove example content
if [ ! -f ".agent_projects/CONVENTIONS.md" ]; then
    # Copy file and remove everything below the divider line
    sed '/^##############################################################################$/,$d' "$SCRIPT_DIR/agent_projects/CONVENTIONS.md" > ".agent_projects/CONVENTIONS.md"
    echo "✅ CONVENTIONS.md copied (example content removed)"
else
    echo "⚠️  CONVENTIONS.md already exists, skipping..."
fi

# Create repository-level files if they don't exist
echo "📄 Creating repository-level tracking files..."

files_to_create=(
    "BACKLOG.md:Project roadmap (names/descriptions only)."
    "TODO.md:Active TODO list"
    "PROGRESS.md:Cross-project milestones, stability metrics, architectural health."
    "DEPRECATED.md:Auto-updated list of deprecated components."
)

for file_info in "${files_to_create[@]}"; do
    filename="${file_info%%:*}"
    description="${file_info#*:}"

    if [ ! -f "$filename" ]; then
        echo "$description" > "$filename"
        echo "✅ Created $filename"
    else
        echo "⚠️  $filename already exists, skipping..."
    fi
done

# Add project setup wizard if requested
if [ "$WIZARD_MODE" = true ]; then
    echo "🧙 Adding project setup wizard..."
    cp "$SCRIPT_DIR/PROJECT_SETUP.md" "PROJECT_SETUP.md"
    echo "✅ Project setup wizard included"
fi

echo ""
echo "🎉 Claude Config setup complete!"
echo ""
if [ "$WIZARD_MODE" = true ]; then
    echo "Next steps:"
    echo "1. Start Claude Code in this directory"
    echo "2. Claude will automatically begin the interactive project setup wizard"
    echo "3. Answer the questions to generate your PROJECT.md"
    echo "4. The wizard will self-delete after completion"
else
    echo "Next steps:"
    echo "1. Edit PROJECT.md to describe your project goals and requirements"
    echo "2. Update .agent_projects/CONVENTIONS.md with your project-specific conventions"
    echo "3. Start Claude Code in this directory - it will automatically use CLAUDE.md"
fi
echo ""
echo "To create a new sub-project:"
echo "  mkdir .agent_projects/my-project"
echo "  cp -r .agent_projects/_template/* .agent_projects/my-project/"
echo ""
if [ "$WIZARD_MODE" = true ]; then
    echo "💡 Tip: The wizard is only for initial PROJECT.md setup. For sub-projects, edit the files manually."
    echo ""
fi
echo "Happy coding with Claude! 🚀"
