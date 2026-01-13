#!/bin/bash
# .devcontainer/setup.sh

# 1. Install Ansible Tools (Needs Sudo for global install)
# We use sudo so these are available globally - TODO: check if there's a better way
echo "Installing Ansible dependencies..."
sudo pip install --no-cache-dir ansible-lint mitogen

# 2. Install Ansible Galaxy Collections
# These install to ~/.ansible, which belongs to the 'vscode' user
ansible-galaxy collection install -r requirements.yml 2>/dev/null || true

# 3. Install ZSH Plugins
# These go into ~/.oh-my-zsh, which is owned by 'vscode'
echo "Installing ZSH plugins..."
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# 4. Configure .zshrc
echo "Configuring minimal ZSH prompt..."

# Enable plugins
sed -i 's/plugins=(git)/plugins=(git ansible zsh-autosuggestions zsh-syntax-highlighting)/g' ~/.zshrc

# Clear default themes
sed -i 's/ZSH_THEME="devcontainers"/ZSH_THEME=""/g' ~/.zshrc
sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME=""/g' ~/.zshrc

# Inject Custom Minimal Prompt
cat <<EOT >> ~/.zshrc

# --- Minimalist No-Nerd-Font Prompt ---
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:*' formats '(%b)' 

# Prompt: user@host dir (branch) $
PROMPT='%F{cyan}%n@%m%f %F{blue}%~%f %F{yellow}\${vcs_info_msg_0_}%f%# '
EOT

echo "Setup complete!"