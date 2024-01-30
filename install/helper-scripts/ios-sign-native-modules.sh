#!/bin/zsh

set -e

# On M1 macs homebrew is located outside /usr/local/bin
if [[ ! $PATH =~ /opt/homebrew/bin: ]]; then
  PATH="/opt/homebrew/bin/:/opt/homebrew/sbin:$PATH"
fi
# Xcode executes script build phases in independant shell environment.
# Force load users configuration file
[ -f "$ZDOTDIR"/.zshrc ] && source "$ZDOTDIR"/.zshrc

# Delete object files
find "$CODESIGNING_FOLDER_PATH/www/nodejs-project/" -name "*.o" -type f -delete
find "$CODESIGNING_FOLDER_PATH/www/nodejs-project/" -name "*.a" -type f -delete

# Create Info.plist for each framework built and loader override.
PATCH_SCRIPT_DIR="$( cd "$PROJECT_DIR" && cd ../../Plugins/@red-mobile/nodejs-mobile-cordova/install/helper-scripts/ && pwd )"
NODEJS_PROJECT_DIR="$( cd "$CODESIGNING_FOLDER_PATH" && cd www/nodejs-project && pwd )"
node "$PATCH_SCRIPT_DIR"/ios-create-plists-and-dlopen-override.js $NODEJS_PROJECT_DIR
# Embed every resulting .framework in the application and delete them afterwards.
embed_framework()
{
  FRAMEWORK_NAME="$(basename "$1")"
  mkdir -p "$TARGET_BUILD_DIR/$FRAMEWORKS_FOLDER_PATH/"
  cp -r "$1" "$TARGET_BUILD_DIR/$FRAMEWORKS_FOLDER_PATH/"
  /usr/bin/codesign --force --sign $EXPANDED_CODE_SIGN_IDENTITY --preserve-metadata=identifier,entitlements,flags --timestamp=none "$TARGET_BUILD_DIR/$FRAMEWORKS_FOLDER_PATH/$FRAMEWORK_NAME"
}
find "$CODESIGNING_FOLDER_PATH/www/nodejs-project/" -name "*.framework" -type d | while read frmwrk_path; do embed_framework "$frmwrk_path"; done

#Delete gyp temporary .deps dependency folders from the project structure.
find "$CODESIGNING_FOLDER_PATH/www/nodejs-project/" -path "*/.deps/*" -delete
find "$CODESIGNING_FOLDER_PATH/www/nodejs-project/" -name ".deps" -type d -delete