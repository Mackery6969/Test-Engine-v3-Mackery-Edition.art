#!/bin/bash

# Change to the directory where the script is located (e.g., art folder)
cd "$(dirname "$0")"

# Set installer path
INSTALL_DIR="./install"

# Function to install Haxe on different platforms
install_haxe() {
  case "$OSTYPE" in
    linux*)
      echo "Installing Haxe for Linux..."
      if [ "$(uname -m)" == "x86_64" ]; then
        HAXE_FILE="haxe-4.3.6-linux64.tar.gz"
      else
        HAXE_FILE="haxe-4.3.6-linux32.tar.gz"
      fi
      if [ -f "$INSTALL_DIR/$HAXE_FILE" ]; then
        tar -xzf "$INSTALL_DIR/$HAXE_FILE" -C /usr/local/
        export PATH="/usr/local/haxe-4.3.6:$PATH"
      else
        echo "Haxe installer not found for Linux. Please check the install directory."
        exit 1
      fi
      ;;

    darwin*)
      echo "Installing Haxe for macOS..."
      if [ -f "$INSTALL_DIR/haxe-4.3.6-osx-installer.pkg" ]; then
        sudo installer -pkg "$INSTALL_DIR/haxe-4.3.6-osx-installer.pkg" -target /
      else
        echo "Haxe installer not found for macOS. Please check the install directory."
        exit 1
      fi
      ;;

    msys*|cygwin*|win32*)
      echo "Installing Haxe for Windows..."
      if [ -f "$INSTALL_DIR/haxe-4.3.6-win64.exe" ]; then
        "$INSTALL_DIR/haxe-4.3.6-win64.exe" /S
      else
        echo "Haxe installer not found for Windows. Please check the install directory."
        exit 1
      fi
      ;;
  esac
}

# Function to install Haxelib and Lime
setup_haxelib_and_lime() {
  echo "Installing Haxelib..."
  haxelib setup

  echo "Running HMM setup for Haxe libraries..."
  haxelib install hmm
  haxelib run hmm setup

  echo "Installing haxelibs specified in hmm.json..."
  hmm install

  echo "Setting up Lime..."
  haxelib install lime
  haxelib run lime setup
}

# Function to install Visual Studio Community 2019 with required components (Windows only)
install_visual_studio_community() {
  if [[ "$OSTYPE" == "msys"* || "$OSTYPE" == "cygwin"* || "$OSTYPE" == "win32"* ]]; then
    # Ensure the download path is in the art folder
    DOWNLOAD_PATH="./vs_community.exe"

    echo "Installing Visual Studio Community with required components..."

    # Download Visual Studio Community installer to the art folder
    curl -k -# -L -o "$DOWNLOAD_PATH" "https://aka.ms/vs/16/release/vs_community.exe"

    # Check if the download succeeded
    if [ -f "$DOWNLOAD_PATH" ]; then
      echo "Download successful: $DOWNLOAD_PATH"

      # Run the installer with the required components
      cmd.exe /c "$DOWNLOAD_PATH --quiet --wait --norestart --nocache ^
        --add Microsoft.VisualStudio.Workload.NativeDesktop ^
        --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 ^
        --add Microsoft.VisualStudio.Component.Windows10SDK.19041 ^
        --includeRecommended"

      # Clean up the installer file after installation
      cmd.exe /c del "$DOWNLOAD_PATH"
    else
      echo "Error: Visual Studio Community installer download failed."
      exit 1
    fi
  fi
}

# Prompt for target platform
prompt_target_platform() {
  read -p "Enter target platform (windows, mac, linux, html5): " TARGET
  case "$TARGET" in
    mac)
      haxelib run lime setup mac
      ;;
    linux)
      haxelib run lime setup linux
      ;;
    html5)
      echo "HTML5 setup is not required, skipping setup..."
      ;;
    *)
      echo "Setting up for Windows..."
      ;;
  esac

  # Optionally rebuild Lime for native platforms
  if [[ "$TARGET" != "html5" ]]; then
    haxelib run lime rebuild "$TARGET"
    haxelib run lime rebuild "$TARGET" -debug
  fi
}

# Run installation steps
install_haxe
setup_haxelib_and_lime
install_visual_studio_community
prompt_target_platform

echo "Setup and testing complete."
