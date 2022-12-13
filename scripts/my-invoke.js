// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { ethers } = require("ethers");
const hre = require("hardhat");

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile 
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // await testNFTMethods();
  // await testStat();
  // await testInvokeSpeed();
  // await testNFTMethods();
  // await testEthTransfer();
  // await testERC20Approve();
  await testHoneyPot();
}

async function testMethods() {
  // We get the deployed contract
  const contract = await hre.ethers.getContractAt("MyERC20", "0x2157dFf27c7CaDa46D1224a3bFC0b1D553408B21");
  const [gov, user1, user2, rewardAdder] = await hre.ethers.getSigners();

  const owner = '0x258af48e28E4A6846E931dDfF8e1Cdf8579821e5';

  var tx = await contract.mint(owner, 1000000000);
  console.log(tx.hash);
  var receipt = await tx.wait();
  console.log(receipt.status);
  console.log('owner balance ', (await contract.balanceOf(owner)).toString());
  // await contract.transfer(gov.address, 100000);
  // console.log('gov balance ', (await contract.balanceOf(gov.address)).toString());

  // await contract.testFail(-2);
  // console.log('user2 balance ', (await contract.balanceOf(user2.address)).toString());

  // await gov.sendTransaction({
  //   to: user1.address,
  //   value: ethers.utils.parseEther("1") // 1 ether
  // })
  // // console.log('1 eth: ', ethers.utils.parseEther("1"));
  // const balanceAfter = await ethers.provider.getBalance(user1.address);
  // console.log('user1 ether balance ', balanceAfter.toString());

}

async function testStat(){
  // We get the deployed contract
  const contract = await hre.ethers.getContractAt("DataStat", "0xB0beaa9Cb690e95Ec1C550322f935EfF90BA97D9");
  let tx = await contract.costManyGas("0xfffffffffffff", 10);
  await tx.wait();
  console.log("txNum: " +  (await contract.txNum()));
}

async function testStat(){
  // We get the deployed contract
  const contract = await hre.ethers.getContractAt("Stat", "0xb4096f86bFb3Df5A0F8a34881aF749dbBB36C9CA");
  let tx = await contract.add();
  await tx.wait();
  console.log("txNum: " +  (await contract.txNum()));
}

async function calculateTps(){
  // We get the deployed contract
  const contract = await hre.ethers.getContractAt("Stat", "0xb4096f86bFb3Df5A0F8a34881aF749dbBB36C9CA");
  const provider = contract.provider; // hre.ethers.getDefaultProvider();
  
  let startHeight = 28291;
  let lastBlock = await provider.getBlock(startHeight);
  console.log(lastBlock);
  let startTime = lastBlock.timestamp;
  let totalTx = lastBlock.transactions.length;

  for(let i = 1; i< 1000; i++){
    let currentBlock = await provider.getBlock(startHeight +i);
    let spendTime = currentBlock.timestamp - lastBlock.timestamp;
    let txCount =  currentBlock.transactions.length;
    if(txCount >0){
      let receipt =   await provider.getTransactionReceipt(currentBlock.transactions[0]);
      console.log("gas used: " + receipt.gasUsed+ " ");
    }
    totalTx += txCount;
    console.log("block number: " + currentBlock.number + " block time: " + new Date(currentBlock.timestamp * 1000) + " tx count: " + txCount + " time spend: " + spendTime + " tps: " + Math.trunc(txCount/spendTime)
     +" miner: " + currentBlock.miner + "total tx count: " + totalTx + " avg tps: " + totalTx / (currentBlock.timestamp - startTime) );
    lastBlock = currentBlock;
  }
}

async function testInvokeSpeed() {
  // We get the deployed contract
  const contract = await hre.ethers.getContractAt("MyERC20", "0xB5F6494a64415F243bB7F7Af39a9dB21Be6E283f");
  // const [gov, user1, user2, rewardAdder] = await hre.ethers.getSigners();

  const owner = '0x258af48e28E4A6846E931dDfF8e1Cdf8579821e5';

  // const contract = await hre.ethers.getContractAt("Stat", "0xb4096f86bFb3Df5A0F8a34881aF749dbBB36C9CA");
  var txlist = [];

  for (let i = 0; i < 10; i++) {
    var startTime = new Date();
    try {
      var tx = await contract.mint(owner, 1000000000 + i);
      // let tx = await contract.setStringList(2200 + i);
      // let tx = await contract.add();
      tx.sendTime = startTime.getTime();
      tx.i = i;
      console.log("[" + new Date() + "] " + i + " " + tx.hash + " rpc response time: " + (new Date().getTime() - startTime.getTime()));
      txlist.push(tx);
    } catch (e) {
      console.log("[" + new Date() + "] " + i + " err tx： " + tx + " err: " + e)
      continue;
    }
  }

  for (var i = 0; i < txlist.length; i++) {
    var tx = txlist[i];
    var receipt = await tx.wait();
    tx.endTime = (await contract.provider.getBlock(receipt.blockNumber)).timestamp * 1000 + 999;
    console.log("[" + new Date() + "]  " + tx.i + " tx hash: " + tx.hash + " gas used: " + receipt.gasUsed + "  spend time: " + (tx.endTime - tx.sendTime));
  }
}

async function testEthTransfer() {
  // We get the deployed contract
  const [gov, user1, user2, rewardAdder] = await hre.ethers.getSigners();

  const owner = '0x258af48e28E4A6846E931dDfF8e1Cdf8579821e5';

  const tx = await gov.sendTransaction({
    to: owner,
    value: ethers.utils.parseEther("1") // 1 ether
  })
  console.log('tx: ', tx);
  const balanceAfter = await ethers.provider.getBalance(owner);
  console.log('user1 ether balance ', balanceAfter.toString());
}

async function testNFTMethods() {
  // maas test 0x4B750643Bf008fB5F54Fc0B1D59a63b582417665
  const contract = await hre.ethers.getContractAt("MyERC721", "0x65c1f49cf008FB4E5062049dF1122AFa2C3A435c");
  const [gov, user1, user2, rewardAdder] = await hre.ethers.getSigners();
  // const accounts = await hre.ethers.getSigners();

  const owner = '0x258af48e28E4A6846E931dDfF8e1Cdf8579821e5';
  const tx = await contract.awardItem(owner);
  const receipt = await tx.wait();

  const [,transferEvent] = receipt.events;
  const { tokenId } = transferEvent.args;
  console.log('tokenId: ', tokenId);
  console.log("owner of token: ", await contract.ownerOf(tokenId));
  
}

async function testERC20Approve() {
  const [deployer] = await hre.ethers.getSigners();
  // cake
  const spender = "0x10ED43C718714eb63d5aA57B78B54704E256024E"; //  honey "0x803Df316D74fb1d2983Cc2dcBEB49492Cdbf09B7";
  const contract = await hre.ethers.getContractAt("MyERC20", "0xe9e7cea3dedca5984780bafc599bd69add087d56");
  const tx = await contract.approve(spender, ethers.utils.parseUnits("10","ether"));
  const receipt = await tx.wait();
  console.log('receipt: ',  receipt);
  const approved = await contract.allowance( deployer.address,"0x803Df316D74fb1d2983Cc2dcBEB49492Cdbf09B7");
  console.log('allowance: ',  approved);
}

// Convert a hex string to a byte array
function hexToBytes(hex) {
  for (var bytes = [], c = 0; c < hex.length; c += 2)
      bytes.push(parseInt(hex.substr(c, 2), 16));
  return bytes;
}

// Convert a byte array to a hex string
function bytesToHex(bytes) {
  for (var hex = [], i = 0; i < bytes.length; i++) {
      var current = bytes[i] < 0 ? bytes[i] + 256 : bytes[i];
      hex.push((current >>> 4).toString(16));
      hex.push((current & 0xF).toString(16));
  }
  return "0x" + hex.join("");
}

function utf8BytesToStr(bytes) {
  let text = ''
  for (let i = 0;i < bytes.length;i++) {
    text += '%' + bytes[i].toString(16)
  }
  return decodeURIComponent(text)
}

async function testHoneyPot() {
  const [deployer, other] = await hre.ethers.getSigners();
  const contract = await hre.ethers.getContractAt("HoneyPot", "0x803Df316D74fb1d2983Cc2dcBEB49492Cdbf09B7");
  // const call = {
  //   router: "0x10ED43C718714eb63d5aA57B78B54704E256024E",
  //   buyAmount0: 10000,
  //   buyAmount1: 0,
  //   sellAmount0: 0,
  //   sellAmount1: 0,
  //   sellPercent: 100,
  //   buyPath:["0xe9e7cea3dedca5984780bafc599bd69add087d56","0x55d398326f99059ff775485246999027b3197955","0x5fac926bf1e638944bb16fb5b787b5ba4bc85b0a"],
  //   sellPath: ["0x5fac926bf1e638944bb16fb5b787b5ba4bc85b0a","0x55d398326f99059ff775485246999027b3197955","0xe9e7cea3dedca5984780bafc599bd69add087d56"],
  //   sig:[
  //       'getAmountsOut(uint256,address[])',
  //       'swapExactTokensForTokensSupportingFeeOnTransferTokens(uint256,uint256,address[],address,uint256)',
  //       'swapExactTokensForTokensSupportingFeeOnTransferTokens(uint256,uint256,address[],address,uint256)',
  //     ],
  //   etherIn: false
  // }
  // wbnb -> jf
  const call = {
    router: "0x10ED43C718714eb63d5aA57B78B54704E256024E",
    buyAmount0: 10000,
    buyAmount1: 0,
    sellAmount0: 0,
    sellAmount1: 0,
    sellPercent: 100,
    buyPath:["0xbb4cdb9cbd36b01bd1cbaebf2de08d9173bc095c","0x55d398326f99059ff775485246999027b3197955","0x5fac926bf1e638944bb16fb5b787b5ba4bc85b0a"],
    sellPath: ["0x5fac926bf1e638944bb16fb5b787b5ba4bc85b0a","0x55d398326f99059ff775485246999027b3197955","0xbb4cdb9cbd36b01bd1cbaebf2de08d9173bc095c"],
    sig:[
        'getAmountsOut(uint256,address[])',
        'swapExactETHForTokensSupportingFeeOnTransferTokens(uint256,address[],address,uint256)',
        'swapExactTokensForETHSupportingFeeOnTransferTokens(uint256,uint256,address[],address,uint256)',
      ],
    etherIn: true
  }

  const tx = await contract.connect(deployer).callStatic.isHoneyPot(call, {value: ethers.utils.parseEther("0.0001")});
  // const receipt = await tx.wait();
  console.log('receipt: ',  tx);
  // console.log('pot: ',  pot);
  // console.log("err: ", utf8BytesToStr(hexToBytes(pot.bytesError)))
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
