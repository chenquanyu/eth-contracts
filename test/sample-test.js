const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Greeter", function () {
  it("Should return the new greeting once it's changed", async function () {
    const Greeter = await ethers.getContractFactory("Greeter");
    const greeter = await Greeter.deploy("Hello, world!");
    await greeter.deployed();

    expect(await greeter.greet()).to.equal("Hello, world!");

    const setGreetingTx = await greeter.setGreeting("Hola, mundo!");

    // wait until the transaction is mined
    await setGreetingTx.wait();

    expect(await greeter.greet()).to.equal("Hola, mundo!");

    
    const setStringListTx = await greeter.setStringList(1000);

    // wait until the transaction is mined
    await setStringListTx.wait();

    // expect(await greeter.greet()).to.equal("Hola, mundo!");
  });
});

describe("MyERC20", function () {
  it("Should return the new greeting once it's changed", async function () {
    const Contract = await hre.ethers.getContractFactory("MyERC20");
    const contract = await Contract.deploy("1000000000000");
    await contract.deployed();

    expect(await contract.name()).to.equal("MT");

    const setStringListTx = await contract.setStringList(1000);

    // wait until the transaction is mined
    await setStringListTx.wait();

    // expect(await greeter.greet()).to.equal("Hola, mundo!");
  });
});
