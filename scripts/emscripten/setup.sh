#!/usr/bin/env bash

# Default EMSDK path and version
EMSDK=${EMSDK:-$HOME/emsdk}
EMSDK_VERSION=${EMSDK_VERSION:-latest}  # Default to 'latest' if unset

check_emsdk() {
    if [ -d "$1/upstream/emscripten" ] && command -v emcc >/dev/null 2>&1; then
        local installed_version=$(emcc --version | head -n1 | cut -d' ' -f3)
        echo "Emscripten version: $installed_version"
        return 0
    else
        return 1
    fi
}

# Preserve EMSDK_VERSION before sourcing emsdk_env.sh
export ORIGINAL_EMSDK_VERSION="$EMSDK_VERSION"

# Install or update Emscripten if needed
if [ ! -d "$EMSDK" ]; then
    echo "===Emscripten SDK not found. Installing...==="
    git clone https://github.com/emscripten-core/emsdk.git "$EMSDK"
    cd "$EMSDK"
else
    echo "===Updating Emscripten SDK...==="
    cd "$EMSDK"
    git pull
fi

./emsdk install "$EMSDK_VERSION"
./emsdk activate "$EMSDK_VERSION"

# Source the environment after installation/activation
source "./emsdk_env.sh"

# Restore EMSDK_VERSION after sourcing
export EMSDK_VERSION="$ORIGINAL_EMSDK_VERSION"

# Verify installation
if check_emsdk "$EMSDK"; then
    echo "Emscripten SDK installed successfully."
else
    echo "Error: Failed to verify Emscripten SDK after installation."
    exit 1
fi

# GitHub Actions environment setup
if [ -n "$GITHUB_ACTIONS" ]; then
    echo "EMSDK=$EMSDK" >> "$GITHUB_ENV"
    echo "EMSCRIPTEN=$EMSDK/upstream/emscripten" >> "$GITHUB_ENV"
fi

# Add to shell config for permanent PATH (optional)
if [ -f "$HOME/.bashrc" ]; then
    echo 'export PATH="'$EMSDK':'$EMSDK'/upstream/emscripten:$PATH"' >> "$HOME/.bashrc"
elif [ -f "$HOME/.zshrc" ]; then
    echo 'export PATH="'$EMSDK':'$EMSDK'/upstream/emscripten:$PATH"' >> "$HOME/.zshrc"
fi

echo "Emscripten setup complete. Ready to build."
