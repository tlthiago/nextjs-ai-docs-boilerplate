#!/bin/bash

echo "🚀 Next.js AI Docs Boilerplate Setup"
echo "=====================================";

# Check if project path is provided
if [ -z "$1" ]; then
    echo "❓ Usage: ./setup.sh <your-project-path>"
    echo "📝 Example: ./setup.sh ~/my-nextjs-project"
    exit 1
fi

PROJECT_PATH="$1"
DOCS_PATH="$PROJECT_PATH/docs"

# Create docs directory if it doesn't exist
echo "📁 Creating docs directory..."
mkdir -p "$DOCS_PATH"

# Copy core files
echo "📋 Copying core documentation files..."
cp -r core/* "$DOCS_PATH/"

# Copy templates
echo "📝 Setting up template files..."
cp templates/README.template.md "$DOCS_PATH/README.md"
cp templates/OVERVIEW.template.md "$DOCS_PATH/01-OVERVIEW.md"

echo ""
echo "✅ Setup complete!"
echo ""
echo "📝 Next steps:"
echo "1. Edit $DOCS_PATH/README.md and replace {{PROJECT_NAME}}, {{PROJECT_DESCRIPTION}}, etc."
echo "2. Edit $DOCS_PATH/01-OVERVIEW.md with your project details"
echo "3. Create BUSINESS-DOMAIN.md with your specific entities"
echo ""
echo "🤖 Your documentation is now AI-agent ready!"
