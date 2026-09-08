#!/bin/bash
# install.sh - Automated Personalization via Standalone Installer

echo "🚀 Starting automated Codespace environment configuration..."

# --------------------------------------------------------
# 1. Update and Upgrade System Packages (Apt)
# --------------------------------------------------------
echo "📦 Updating package lists and upgrading system packages..."
sudo apt-get update -y


# --------------------------------------------------------
# 2. Force Standalone Claude Code Native Installer
# --------------------------------------------------------
echo "🤖 Executing standalone native installer for Claude Code..."
# Installs directly from Anthropic's production asset URL
curl -fsSL https://claude.ai/install.sh | bash

# Ensure the local binary directory exists and is integrated into the PATH
export PATH="$HOME/.local/bin:$PATH"


# --------------------------------------------------------
# 3. Bypass Claude Code Onboarding Configuration Screen
# --------------------------------------------------------
echo "⚙️ Suppressing Claude Code introductory onboarding..."
mkdir -p ~/.claude

# Mark onboarding completed to skip the initial prompt wall
cat << 'EOF' > ~/.claude.json
{
  "hasCompletedOnboarding": true
}
EOF

# Seed a default UI experience config file
cat << 'EOF' > ~/.claude/settings.json
{
  "theme": "dark",
  "verbose": false
}
EOF


# --------------------------------------------------------
# 4. Enforce Zsh as the Default VS Code Shell Profile
# --------------------------------------------------------
echo "🐚 Changing the default terminal profile to Zsh..."
mkdir -p ~/.string_config/Code/User
mkdir -p ~/.config/Code/User

# Ensure standard user environments automatically recognize the new binary path
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc

VSCODE_SETTINGS=$(cat << 'EOF'
{
  "terminal.integrated.defaultProfile.linux": "zsh"
}
EOF
)

# Apply terminal profile preferences across configuration paths
echo "$VSCODE_SETTINGS" > ~/.string_config/Code/User/settings.json
echo "$VSCODE_SETTINGS" > ~/.config/Code/User/settings.json

echo "✨ Environment deployment successfully finished!"
