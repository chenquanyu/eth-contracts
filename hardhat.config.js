require("dotenv").config();

require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-waffle");
require("hardhat-gas-reporter");
require("solidity-coverage");
const baas = require("./.networks/baas");
// const polyTestnet = require("./.networks/poly-testnet");
const ethTestnet = require("./.networks/eth-testnet");
const bscMainnet = require("./.networks/bsc-mainnet");
const maasMainnet = require("./.networks/maas-mainnet");
const maasDev = require("./.networks/maas-dev");
const maasTest = require("./.networks/maas-test");
const maasStress = require("./.networks/maas-stress");

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more


function __init_networks__() {
  let networks = {};
  networks.baas = baas;
  // networks.polyTestnet = polyTestnet;
  // networks.nftTestnet = nftTestnet;
  networks.maasMainnet = maasMainnet;
  networks.maasDev = maasDev;
  networks.maasTest = maasTest;
  networks.maasStress = maasStress;
  networks.ethTestnet = ethTestnet;
  networks.bscMainnet = bscMainnet;
  // networks.bscTestnet = bscTestnet;
  // networks.localTestnet = localTestnet;
  return networks;
}

function __init_etherscan__() {
  let etherscan = {};
  etherscan = apiKey;
  return etherscan;
}

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    version: "0.8.2",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: __init_networks__(),
  // etherscan: __init_etherscan__(),
  abiExporter: {
    path: './abi',
    clear: true,
    flat: false,
    only: [],
    spacing: 2
  },
  gasReporter: {
    enabled: true, //process.env.REPORT_GAS !== undefined,
    //currency: "USD",
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
};
