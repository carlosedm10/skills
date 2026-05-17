#!/usr/bin/env node
/**
 * CLI entry for npm/bun: forwards to install.sh (same UX as cloning the repo).
 *
 * Usage:
 *   npx agent-skills-template [install] [install.sh args...]
 *   npm i -g agent-skills-template && agent-skills-template install --help
 */

const { spawnSync } = require("child_process");
const fs = require("fs");
const path = require("path");

const root = path.resolve(__dirname, "..");
const installSh = path.join(root, "install.sh");

function main() {
  const argv = process.argv.slice(2);
  let forwarded = argv;

  if (argv[0] === "install") {
    forwarded = argv.slice(1);
  }

  if (!fs.existsSync(installSh)) {
    console.error(`Missing installer at ${installSh}`);
    process.exit(1);
  }

  const result = spawnSync("bash", [installSh, ...forwarded], {
    stdio: "inherit",
    cwd: root,
    env: process.env,
  });

  if (result.error) {
    console.error(result.error.message);
    process.exit(1);
  }

  process.exit(result.status === null ? 1 : result.status);
}

main();
