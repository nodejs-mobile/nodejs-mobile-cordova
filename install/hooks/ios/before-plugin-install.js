var fs = require('fs');

const nodeProjectFolder = 'www/nodejs-project';
const nodeMobileFolderPath = 'plugins/nodejs-mobile-cordova/libs/ios/nodemobile/';
const nodeMobileFileName = 'NodeMobile.xcframework';
const nodeMobileFilePath = nodeMobileFolderPath + nodeMobileFileName;
const zipFileName = nodeMobileFileName + '.tar.zip';
const zipFilePath = nodeMobileFolderPath + zipFileName

module.exports = function(context) {
  // Create the node project folder if it doesn't exist
  if (!fs.existsSync(nodeProjectFolder)) {
    fs.mkdirSync(nodeProjectFolder);
  }

  return new Promise((resolve, reject) => {
      // Unzip and untar the libnode.Framework
    if (fs.existsSync(zipFilePath)) {

      var tar = require('tar');
      tar.extract({
        cwd: nodeMobileFolderPath,
        file: zipFilePath,
        onwarn: (code,msg,err) => {
          reject(err);
        },
      })
      .then(_ => {
        fs.unlinkSync(zipFilePath);
        resolve();
      });

    } else if (!fs.existsSync(nodeMobileFilePath)) {
      reject(new Error(nodeMobileFileName + ' is missing'));
    } else {
        resolve();
    }
  });
}
