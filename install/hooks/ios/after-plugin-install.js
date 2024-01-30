var path = require('path');
var fs = require('fs');

module.exports = function(context) {
  var xcode = require('xcode');

  // Require the iOS platform Api to get the Xcode .pbxproj path.
  var iosPlatformPath = path.join(context.opts.projectRoot, 'platforms', 'ios');
  var iosAPI = require(path.join(iosPlatformPath, 'cordova', 'Api'));
  var iosAPIInstance = new iosAPI('ios', iosPlatformPath);
  var pbxprojPath = iosAPIInstance.locations.pbxproj;

  // Read the Xcode project and get the target.
  var xcodeProject = xcode.project(pbxprojPath);
  xcodeProject.parseSync();
  var firstTargetUUID = xcodeProject.getFirstTarget().uuid;

  // Adds a build phase to rebuild native modules.
  var rebuildNativeModulesBuildPhaseName = 'Build Node.js Mobile Native Modules';
  var rebuildNativeModulesBuildPhaseScript = 'zsh "$PROJECT_DIR/../../plugins/@red-mobile/nodejs-mobile-cordova/install/helper-scripts/ios-build-native-modules.sh"'
  var rebuildNativeModulesBuildPhase = xcodeProject.buildPhaseObject('PBXShellScriptBuildPhase', rebuildNativeModulesBuildPhaseName, firstTargetUUID);
  if (!(rebuildNativeModulesBuildPhase)) {
    xcodeProject.addBuildPhase(
      [],
      'PBXShellScriptBuildPhase',
      rebuildNativeModulesBuildPhaseName,
      firstTargetUUID,
      { shellPath: '/bin/zsh', shellScript: rebuildNativeModulesBuildPhaseScript }
    );
  }

  // Adds a build phase to sign native modules.
  var signNativeModulesBuildPhaseName = 'Sign Node.js Mobile Native Modules';
  var signNativeModulesBuildPhaseScript = 'zsh "$PROJECT_DIR/../../plugins/@red-mobile/nodejs-mobile-cordova/install/helper-scripts/ios-sign-native-modules.sh"'
  var signNativeModulesBuildPhase = xcodeProject.buildPhaseObject('PBXShellScriptBuildPhase', signNativeModulesBuildPhaseName, firstTargetUUID);
  if (!(signNativeModulesBuildPhase)) {
    xcodeProject.addBuildPhase(
      [],
      'PBXShellScriptBuildPhase',
      signNativeModulesBuildPhaseName,
      firstTargetUUID,
      { shellPath: '/bin/zsh', shellScript: signNativeModulesBuildPhaseScript }
    );
  }

  // Write the changes into the Xcode project.
  fs.writeFileSync(pbxprojPath, xcodeProject.writeSync());
}
