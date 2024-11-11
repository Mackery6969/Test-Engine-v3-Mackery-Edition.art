#!/bin/bash

# Parameters
TARGET="${1:-linux}"                  # Default to Linux if not provided
BUILD_DEFINES="${2:-"-DGITHUB_BUILD"}" # Default build defines
BUILD_GAME="${3:-false}"               # Default to not building the game
IS_GITHUB_ACTION="${4:-false}"         # Default to false if not in GitHub Actions

# Echo received parameters for debugging
echo "Received parameters:"
echo "TARGET: $TARGET"
echo "BUILD_DEFINES: $BUILD_DEFINES"
echo "BUILD_GAME: $BUILD_GAME"
echo "IS_GITHUB_ACTION: $IS_GITHUB_ACTION"

# Set install directory and navigate to script directory
cd "$(dirname "$0")"
INSTALL_DIR="./install"

# Function to install Haxe on different platforms (only runs if not in GitHub Actions)
install_haxe() {
  if [ "$IS_GITHUB_ACTION" != "true" ]; then
    case "$OSTYPE" in
      linux*)
        HAXE_FILE="haxe-4.3.6-linux64.tar.gz"
        [ "$(uname -m)" != "x86_64" ] && HAXE_FILE="haxe-4.3.6-linux32.tar.gz"
        [ -f "$INSTALL_DIR/$HAXE_FILE" ] && sudo tar -xzf "$INSTALL_DIR/$HAXE_FILE" -C /usr/local/ || { echo "Haxe installer not found"; exit 1; }
        export PATH="/usr/local/haxe-4.3.6:$PATH"
        ;;
      darwin*)
        [ -f "$INSTALL_DIR/haxe-4.3.6-osx-installer.pkg" ] && sudo installer -pkg "$INSTALL_DIR/haxe-4.3.6-osx-installer.pkg" -target / || { echo "Haxe installer not found"; exit 1; }
        ;;
      msys*|cygwin*|win32*)
        [ -f "$INSTALL_DIR/haxe-4.3.6-win64.exe" ] && { chmod +x "$INSTALL_DIR/haxe-4.3.6-win64.exe"; "$INSTALL_DIR/haxe-4.3.6-win64.exe" /S; } || { echo "Haxe installer not found"; exit 1; }
        ;;
    esac
  else
    echo "Skipping Haxe installation (handled by GitHub Actions setup-haxe)."
  fi
}

# Run Haxe installation
install_haxe

# Move to parent directory to locate hmm.json and other project files
cd ..

# Function to set up Haxelib and Lime, plus additional Git dependencies
setup_haxelib_and_lime() {
  haxelib setup "$HOME/haxelib"
  haxelib install hxp 1.3.0
  haxelib git openfl https://github.com/FunkinCrew/openfl
  haxelib git flixel https://github.com/FunkinCrew/flixel
  haxelib git flixel-addons https://github.com/FunkinCrew/flixel-addons
  haxelib git haxeui-core https://github.com/haxeui/haxeui-core
  haxelib git haxeui-flixel https://github.com/haxeui/haxeui-flixel
  haxelib git hxjsonast https://github.com/nadako/hxjsonast
  haxelib install hmm
  haxelib run hmm setup
  haxelib run hmm install
  haxelib install lime
  haxelib run lime setup
}

# Function to install Visual Studio Community (Windows only)
install_visual_studio_community() {
  if [[ "$OSTYPE" == "msys"* || "$OSTYPE" == "cygwin"* || "$OSTYPE" == "win32"* ]]; then
    DOWNLOAD_PATH="./vs_community.exe"
    curl -k -# -L -o "$DOWNLOAD_PATH" "https://aka.ms/vs/16/release/vs_community.exe"
    if [ -f "$DOWNLOAD_PATH" ]; then
      echo "Installing Visual Studio Community with required components..."
      cmd.exe /c "$DOWNLOAD_PATH --quiet --wait --norestart --nocache ^ --add Microsoft.VisualStudio.Workload.NativeDesktop ^ --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 ^ --add Microsoft.VisualStudio.Component.Windows10SDK.19041 ^ --includeRecommended"
      cmd.exe /c del "$DOWNLOAD_PATH"
    else
      echo "Error: Visual Studio Community installer download failed."
      exit 1
    fi
  fi
}

# Function to build the game if the build flag is true
build_game() {
  if [ "$BUILD_GAME" = "true" ]; then
    echo "Building game for target platform: $TARGET with defines: $BUILD_DEFINES"
    haxelib run lime build -project project.hxp "$TARGET" -v -release --times "$BUILD_DEFINES"
  else
    echo "Skipping game build as requested."
  fi
}

# Run remaining setup and build steps
setup_haxelib_and_lime
install_visual_studio_community
build_game

echo "Setup and build process complete."
