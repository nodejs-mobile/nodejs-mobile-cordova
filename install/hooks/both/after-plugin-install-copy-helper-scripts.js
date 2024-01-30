const fs = require('fs');
const path = require('path');

module.exports = function(context)
{
  fs.copyFileSync(
    path.join(context.opts.plugin.dir, "install/helper-scripts/rebuild-native-modules.sh"),
    path.join(context.opts.projectRoot, "rebuild-native-modules.sh")
  )
}
