#!/bin/bash
#  Copyright (C) 2026 Leonardo Rossi
#  SPDX-License-Identifier: GPL-3.0-or-later

clear
# 1. Definisci le variabili per non ripeterle
SDK_NAME="swift-6.3-DEVELOPMENT-SNAPSHOT-2025-12-07-a_android"
BUILD_DIR=".build-android"

# 2. Pulisci la vecchia build (rimuove solo la cartella Android, non quella di Xcode!)
echo "🧹  Pulisco la build Android..."
swift package clean
rm -rf "$BUILD_DIR"
    
# 3. Lancia la build da zero
echo "🚀  Compilo per Android..."
swift build \
    --build-path "$BUILD_DIR" \
    --swift-sdk "$SDK_NAME" \
    --triple aarch64-unknown-linux-android
    
echo "🧹  Elimino per ora la build Android..."
rm -rf "$BUILD_DIR"
