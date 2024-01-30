#!/bin/zsh

set -e

# On M1 macs homebrew is located outside /usr/local/bin
if [[ ! $PATH =~ /opt/homebrew/bin: ]]; then
  PATH="/opt/homebrew/bin/:/opt/homebrew/sbin:$PATH"
fi
# Xcode executes script build phases in independant shell environment.
# Force load users configuration file
[ -f "$ZDOTDIR"/.zshrc ] && source "$ZDOTDIR"/.zshrc

NODEPROJ="$CODESIGNING_FOLDER_PATH/www/nodejs-project/"

if [ -z "$NODEJS_MOBILE_BUILD_NATIVE_MODULES" ]; then
# If build native modules preference is not set, look for it in the project's
# www/NODEJS_MOBILE_BUILD_NATIVE_MODULES_VALUE.txt
  PREFERENCE_FILE_PATH="$CODESIGNING_FOLDER_PATH/www/NODEJS_MOBILE_BUILD_NATIVE_MODULES_VALUE.txt"
  if [ -f "$PREFERENCE_FILE_PATH" ]; then
    NODEJS_MOBILE_BUILD_NATIVE_MODULES="$(cat $PREFERENCE_FILE_PATH | xargs)"
  fi
fi
if [ -z "$NODEJS_MOBILE_BUILD_NATIVE_MODULES" ]; then
# If build native modules preference is not set, try to find .gyp files
#to turn it on.
  gypfiles=($(find "$NODEPROJ" -type f -name "*.gyp"))
  if [ ${#gypfiles[@]} -gt 0 ]; then
    NODEJS_MOBILE_BUILD_NATIVE_MODULES=1
  else
    NODEJS_MOBILE_BUILD_NATIVE_MODULES=0
  fi
fi

if [ "1" != "$NODEJS_MOBILE_BUILD_NATIVE_MODULES" ]; then exit 0; fi

# Delete object files that may already come from within the npm package.
find "$NODEPROJ" -name "*.o" -type f -delete
find "$NODEPROJ" -name "*.a" -type f -delete

# Function to skip compilation of a prebuilt module
preparePrebuiltModule()
{
  local DOT_NODE_PATH="$1"
  local DOT_NODE_FULL="$(cd "$(dirname -- "$DOT_NODE_PATH")" >/dev/null; pwd -P)/$(basename -- "$DOT_NODE_PATH")"
  local MODULE_ROOT="$(cd $DOT_NODE_PATH && cd .. && cd .. && cd .. && pwd)"
  local MODULE_NAME="$(basename $MODULE_ROOT)"
  echo "Preparing to use the prebuild in $MODULE_NAME"
  # Move the prebuild to the correct folder:
  rm -rf $MODULE_ROOT/build
  mkdir -p $MODULE_ROOT/build/Release
  mv $DOT_NODE_FULL $MODULE_ROOT/build/Release/
  # Hack the npm package to forcefully disable compile-on-install:
  rm -rf $MODULE_ROOT/binding.gyp
  sed -i.bak 's/"install"/"dontinstall"/g; s/"rebuild"/"dontrebuild"/g; s/"gypfile"/"dontgypfile"/g' $MODULE_ROOT/package.json
}

# Delete bundle contents that may be there from previous builds.
# Handle the special case where the module has a prebuild that we want to use
if [[ "$PLATFORM_PREFERRED_ARCH" == "arm64" ]]; then
  PREBUILD_ARCH="arm64"
else
  PREBUILD_ARCH="x64"
fi
if [[ "$PLATFORM_NAME" == "iphonesimulator" ]] && [[ "$NATIVE_ARCH" == "arm64" ]]; then
  SUFFIX="-simulator"
  PREBUILD_ARCH="arm64"
else
  SUFFIX=""
fi
find -E "$NODEPROJ" \
    ! -regex ".*/prebuilds/ios-$PREBUILD_ARCH$SUFFIX" \
    -regex '.*/prebuilds/[^/]*$' -type d \
    -prune -exec rm -rf "{}" \;
find -E "$NODEPROJ" \
    ! -regex ".*/prebuilds/ios-$PREBUILD_ARCH$SUFFIX/.*\.node$" \
    -name '*.node' -type f \
    -exec rm "{}" \;
find "$NODEPROJ" \
    -name "*.framework" -type d \
    -prune -exec rm -rf "{}" \;
for DOT_NODE in `find -E "$NODEPROJ" -regex ".*/prebuilds/ios-$PREBUILD_ARCH$SUFFIX/.*\.node$" -type d`; do
  preparePrebuiltModule "$DOT_NODE"
done

# Symlinks to binaries are resolved by cordova prepare during the copy, causing build time errors.
# The original project's .bin folder will be added to the path before building the native modules.
find "$NODEPROJ" -path "*/.bin/*" -delete
find "$NODEPROJ" -name ".bin" -type d -delete
# Get the nodejs-mobile-gyp location
if [ -d "$PROJECT_DIR/../../plugins/@red-mobile/nodejs-mobile-cordova/node_modules/nodejs-mobile-gyp/" ]; then
NODEJS_MOBILE_GYP_DIR="$( cd "$PROJECT_DIR" && cd ../../plugins/@red-mobile/nodejs-mobile-cordova/node_modules/nodejs-mobile-gyp/ && pwd )"
else
NODEJS_MOBILE_GYP_DIR="$( cd "$PROJECT_DIR" && cd ../../node_modules/nodejs-mobile-gyp/ && pwd )"
fi
NODEJS_MOBILE_GYP_BIN_FILE="$NODEJS_MOBILE_GYP_DIR"/bin/node-gyp.js
# Rebuild modules with right environment
NODEJS_HEADERS_DIR="$( cd "$( dirname "$PRODUCT_SETTINGS_PATH" )" && cd Plugins/@red-mobile/nodejs-mobile-cordova/ && pwd )"
# Adds the original project .bin to the path. It's a workaround
# to correctly build some modules that depend on symlinked modules,
# like node-pre-gyp.
if [ -d "$PROJECT_DIR/../../www/nodejs-project/node_modules/.bin/" ]; then
  PATH="$PROJECT_DIR/../../www/nodejs-project/node_modules/.bin/:$PATH"
fi

pushd $NODEPROJ
export GYP_DEFINES="OS=ios"
export npm_config_nodedir="$NODEJS_HEADERS_DIR"
export npm_config_node_gyp="$NODEJS_MOBILE_GYP_BIN_FILE"
export npm_config_format="make-ios"
export npm_config_node_engine="chakracore"
export NODEJS_MOBILE_GYP="$NODEJS_MOBILE_GYP_BIN_FILE"
export npm_config_platform="ios"

if [[ "$PLATFORM_NAME" == "iphoneos" ]]; then
  export npm_config_arch="arm64"
else
  if [[ "$HOST_ARCH" == "arm64" ]] ; then # M1 mac
    export GYP_DEFINES="OS=ios iossim=true"
    export npm_config_arch="arm64"
  else
    export npm_config_arch="x64"
  fi
fi
npm --verbose rebuild --build-from-source
popd