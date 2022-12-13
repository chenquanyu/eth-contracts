// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile 
  // manually to make sure everything is compiled
   await hre.run('compile');

  // We get the contract to deploy
  const Greeter = await hre.ethers.getContractFactory("MyERC721");
  const greeter = await Greeter.deploy();

  await greeter.deployed();

  console.log("KC 721 deployed to:", greeter.address);
  await testMethods(greeter);
}

async function testMethods(contract) {
  console.log("Test start:", contract.address);
  const name = await contract.name();
  console.log("KC name:", name);
  console.log("KC symbol:", (await contract.symbol()).toString());
  const accounts = await ethers.getSigners();
  console.log("KC balanceOf:", accounts[0].address , (await contract.balanceOf(accounts[0].address)).toString());
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
