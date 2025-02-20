#!/usr/bin/env bash

EMSDK=${EMSDK:-$HOME/emsdk}
EMSDK_VERSION=${EMSDK_VERSION:-latest} # "3.1.20"

check_emsdk() {
    if [ -d "$1/upstream/emscripten" ]; then
        local installed_version=$(emcc --version | head -n1 | cut -d' ' -f3)
        if [ "$installed_version" != "$EMSDK_VERSION" ] && [ "$EMSDK_VERSION" != "latest" ]; then
            echo "Installed version ($installed_version) does not match desired version ($EMSDK_VERSION)."
            return 1
        fi
        echo "Emscripten version: $installed_version"
        return 0
    else
        return 1
    fi
}

if check_emsdk "$EMSDK"; then
    echo "Emscripten SDK already installed at $EMSDK"
else
    echo "===Emscripten SDK not found. Installing...==="
    if [ ! -d "$EMSDK" ]; then
        git clone https://github.com/emscripten-core/emsdk.git "$EMSDK"
    else
        cd "$EMSDK"
        git pull
    fi
    cd "$EMSDK"
    ./emsdk install "$EMSDK_VERSION"
    ./emsdk activate "$EMSDK_VERSION"

     if [ -n "$GITHUB_ACTIONS" ]; then
        echo "EMSDK_PATH=$HOME/emsdk" >> $GITHUB_ENV
        echo "EMSCRIPTEN=$HOME/emsdk/upstream/emscripten" >> $GITHUB_ENV
    fi
    source "$EMSDK_PATH/emsdk_env.sh"

    # Check if .bashrc or .zshrc exists to add the path permanently
    if [ -f "$HOME/.bashrc" ]; then
        echo 'export PATH="$HOME/emsdk:$HOME/emsdk/upstream/emscripten:$PATH"' >> "$HOME/.bashrc"
    elif [ -f "$HOME/.zshrc" ]; then
        echo 'export PATH="$HOME/emsdk:$HOME/emsdk/upstream/emscripten:$PATH"' >> "$HOME/.zshrc"
    fi

    if check_emsdk "$EMSDK"; then
        echo "Emscripten SDK installed successfully."
    else
        echo "Error: Failed to install Emscripten SDK."
        exit 1
    fi
fi

source "$EMSDK/emsdk_env.sh"
