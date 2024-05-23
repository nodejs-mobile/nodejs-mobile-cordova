const fs = require("fs");
const tar = require("tar");

const nodeProjectFolder = "www/nodejs-project";
const nodeMobileFolderPath = "plugins/nodejs-mobile-cordova/libs/ios/nodemobile/";
const nodeMobileFileName = "NodeMobile.xcframework";
const nodeMobileFilePath = nodeMobileFolderPath + nodeMobileFileName;
const zipFileName = nodeMobileFileName + ".tar.zip";
const zipFilePath = nodeMobileFolderPath + zipFileName;

module.exports = async function () {
  // Create the node project folder if it doesn't exist
  if (!fs.existsSync(nodeProjectFolder)) {
    fs.mkdirSync(nodeProjectFolder);
  }

  // Unzip and untar the libnode.Framework
  if (fs.existsSync(zipFilePath)) {
    await tar.extract({
      file: zipFilePath,
      cwd: nodeMobileFolderPath,
    });

    fs.unlinkSync(zipFilePath);
  } else if (!fs.existsSync(nodeMobileFilePath)) {
    throw new Error(nodeMobileFileName + " is missing");
  }
};
