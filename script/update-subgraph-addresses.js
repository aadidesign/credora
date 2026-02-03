#!/usr/bin/env node
/**
 * Update subgraph.yaml with deployed contract addresses
 * Usage: node script/update-subgraph-addresses.js <scoreSBT> <permissionManager> <scoreOracle>
 */

const fs = require("fs");
const path = require("path");

const args = process.argv.slice(2);
if (args.length < 3) {
  console.error("Usage: node update-subgraph-addresses.js <scoreSBT> <permissionManager> <scoreOracle>");
  process.exit(1);
}

const [scoreSBT, permissionManager, scoreOracle] = args;
const subgraphPath = path.join(__dirname, "../packages/subgraph/subgraph.yaml");
let yaml = fs.readFileSync(subgraphPath, "utf8");

const placeholder = "0x0000000000000000000000000000000000000000";
let count = 0;
yaml = yaml.replace(new RegExp(`address: "${placeholder}"`, "g"), () => {
  const addrs = [scoreSBT, permissionManager, scoreOracle];
  return `address: "${addrs[count++]}"`;
});

fs.writeFileSync(subgraphPath, yaml);
console.log("Updated packages/subgraph/subgraph.yaml");
