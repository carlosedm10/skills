#!/usr/bin/env node
/**
 * CLI entry for npm/bun: forwards to ./install (same UX as cloning the repo).
 *
 * Usage:
 *   npx agent-skills-template [install] [install args...]
 *   npm i -g agent-skills-template && agent-skills-template install --help
 */

const { spawnSync } = require("child_process");
const fs = require("fs");
const path = require("path");

const root = path.resolve(__dirname, "..");
const installer = path.join(root, "install");

function main() {
  const argv = process.argv.slice(2);
  let forwarded = argv;

  if (argv[0] === "install") {
    forwarded = argv.slice(1);
  }

  if (!fs.existsSync(installer)) {
    console.error(`Missing installer at ${installer}`);
    process.exit(1);
  }

  const result = spawnSync("bash", [installer, ...forwarded], {
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
