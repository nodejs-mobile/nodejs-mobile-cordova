#!/bin/zsh

# Delete object files that may already come from within the npm package.
find "nodejs-project" -name "*.o" -type f -delete
find "nodejs-project" -name "*.a" -type f -delete
find "nodejs-project" -name "*.node" -type f -delete

# Delete bundle contents that may be there from previous builds.
find "nodejs-project" -path "*/*.node/*" -delete
find "nodejs-project" -name "*.node" -type d -delete

NATIVE_MODULES=($(find "nodejs-project" -type f -name "binding.gyp" | sed -E 's|/[^/]+$||' | sort -u))

echo "Found ${#NATIVE_MODULES[@]} native modules"

for module in "${NATIVE_MODULES[@]}"
do
    pushd "$module"
    echo "Building $(basename $module) for iOS devices"
    npx prebuild-for-nodejs-mobile ios-arm64
    echo "Building $(basename $module) for iOS simulator"
    if [[ $(uname -m) == 'arm64' ]] # if M1 mac
    then
        npx prebuild-for-nodejs-mobile ios-arm64-simulator
    else
        npx prebuild-for-nodejs-mobile ios-x64-simulator
    fi
    echo "Building $(basename $module) for Android arm64"
    npx prebuild-for-nodejs-mobile android-arm64
    echo "Building $(basename $module) for Android arm"
    npx prebuild-for-nodejs-mobile android-arm
    echo "Building $(basename $module) for Android x86"
    npx prebuild-for-nodejs-mobile android-x64
    popd
done
