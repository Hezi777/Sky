const { execSync } = require("child_process");
const path = require("path");

module.exports = async function (context) {
  const dmgFiles = context.artifactPaths.filter((p) => p.endsWith(".dmg"));
  for (const dmg of dmgFiles) {
    console.log(`Fixing hidden flags in ${path.basename(dmg)}...`);
    execSync(`bash scripts/fix-dmg.sh "${dmg}"`, { stdio: "inherit" });
  }
  return [];
};
