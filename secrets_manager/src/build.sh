#!/bin/bash

SCRIPT_DIR="$(dirname $0)"
TARGET_DIR="$SCRIPT_DIR/dist"

rm -rf "$TARGET_DIR"
mkdir "$TARGET_DIR"
cp "$SCRIPT_DIR/lambda.py" "$TARGET_DIR"
