// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { RLP } = require("ethers/lib/utils");
const hre = require("hardhat");

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile 
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // await testMethods();
  await testMaasConfig();
  // await testNodeManager();
  // await maasTestConfig();
  // await maasMainConfig();
}

async function maasMainConfig() {
  const signers = await hre.ethers.getSigners();
  const owner = signers[1];

  // We get the native contract
  const maasConfigAddress = '0xD62B67170A6bb645f1c59601FbC6766940ee12e5';
  var contract = await hre.ethers.getContractAt("IMaasConfig", maasConfigAddress, signers[0]);
  console.log('owner: ', (await contract.getOwner()).toString());
  console.log('getGasManagerList: ', (await contract.getGasManagerList()));
  console.log('blacklist: ', (await contract.getBlacklist()));

  // console.log('owner: ', (await contract.getOwner()).toString());
  // var tx =  await contract.changeOwner(owner.address);
  // console.log(tx.hash);
  // var receipt = await tx.wait();
  // console.log(receipt.status);
  // console.log('new owner: ', (await contract.getOwner()).toString());

  // tx =  await contract.setGasManager("", true);
  // console.log(tx.hash);
  // receipt = await tx.wait();
  // console.log(receipt.status);
  // console.log('getGasManagerList: ', (await contract.getGasManagerList()));

}

async function maasTestConfig() {
  const signers = await hre.ethers.getSigners();
  const owner = signers[0];

  // We get the native contract
  const maasConfigAddress = '0xD62B67170A6bb645f1c59601FbC6766940ee12e5';
  var contract = await hre.ethers.getContractAt("IMaasConfig", maasConfigAddress, signers[0]);
  console.log('owner: ', (await contract.getOwner()).toString());

  // console.log('owner: ', (await contract.getOwner()).toString());
  // var tx =  await contract.changeOwner(owner.address);
  // console.log(tx.hash);
  // var receipt = await tx.wait();
  // console.log(receipt.status);
  // console.log('new owner: ', (await contract.getOwner()).toString());

  tx =  await contract.setGasManager("0x31908D48cE88E354B26Ec71af3117303E1b663A1", true);
  console.log(tx.hash);
  receipt = await tx.wait();
  console.log(receipt.status);
  console.log('getGasManagerList: ', (await contract.getGasManagerList()));

  // tx =  await contract.setGasManager("0xeaf4ffBf7e815d0570D8c8b9489cFD4A7af57F31", true);
  // console.log(tx.hash);
  // receipt = await tx.wait();
  // console.log(receipt.status);
  // console.log('getGasManagerList: ', (await contract.getGasManagerList()));

}

async function testMaasConfig() {
  const signers = await hre.ethers.getSigners();

  const address = '0xD62B67170A6bb645f1c59601FbC6766940ee12e5';
  // const blockedAccount ="0x5bCA6B1c89e1f4f77b6ad1A0b9b8362c4b316556";
  const owner = signers[0].address;
  
  // tx = await signers[0].sendTransaction({
  //       to: signers[4].address,
  //       value: ethers.utils.parseEther("1") // 1 ether
  //     })
  // receipt = await tx.wait();
  // console.log(receipt.status);

   // We get the native contract
   var contract = await hre.ethers.getContractAt("IMaasConfig", address, signers[0]);

  //  await contract.mint(owner, 1000000000);
  console.log('contract name: ', (await contract.name()).toString());
  console.log('blacklist: ', (await contract.getBlacklist()).toString());
  console.log('gas user list: ', (await contract.getGasUserList()).toString());
  console.log('owner: ', (await contract.getOwner()).toString());
  
  // owner
  // (function (){

  // })();
  // console.log('owner: ', (await contract.getOwner()).toString());
  // var tx =  await contract.changeOwner(owner);
  // console.log(tx.hash);
  // var receipt = await tx.wait();
  // console.log(receipt.status);
  // console.log('new owner: ', (await contract.getOwner()).toString());
  
  // // block account
  // tx =  await contract.blockAccount(blockedAccount, true);
  // console.log(tx.hash);
  // receipt = await tx.wait();
  // console.log(receipt.status);
  // console.log('isBlocked: ', (await contract.isBlocked(blockedAccount)));
  // console.log('blacklist: ', (await contract.getBlacklist()));

  // tx =  await contract.blockAccount(blockedAccount, false);
  // console.log(tx.hash);
  // receipt = await tx.wait();
  // console.log(receipt.status);
  // console.log('isBlocked: ', (await contract.isBlocked(blockedAccount)));
  // console.log('blacklist: ', (await contract.getBlacklist()));

  // // gas manage
  // tx =  await contract.enableGasManage(true);
  // console.log(tx.hash);
  // receipt = await tx.wait();
  // console.log(receipt.status);
  // console.log('isGasManageEnabled: ', (await contract.isGasManageEnabled()));

  // tx =  await contract.setGasManager(signers[0].address, false);
  // console.log(tx.hash);
  // receipt = await tx.wait();
  // console.log(receipt.status);
  // console.log('isGasManager: ', (await contract.isGasManager(signers[0].address)));
  // console.log('getGasManagerList: ', (await contract.getGasManagerList()));

  // // shoud fail
  // try {
  //   tx = await signers[0].sendTransaction({
  //     to: signers[1].address,
  //     value: ethers.utils.parseEther("1") // 1 ether
  //   })
  //   receipt = await tx.wait();
  //   console.log(receipt.status);
  // } catch (error) {
  //   console.log("Transfering eth needs gas manager.")
  // }
  
  // tx =  await contract.setGasManager(signers[0].address, true);
  // console.log(tx.hash);
  // receipt = await tx.wait();
  // console.log(receipt.status);
  // console.log('isGasManager: ', (await contract.isGasManager(signers[0].address)));
  // console.log('getGasManagerList: ', (await contract.getGasManagerList()));

  tx =  await contract.setGasUsers([signers[0].address], true);
  console.log(tx.hash);
  receipt = await tx.wait();
  console.log(receipt.status);
  console.log('isGasUser: ', (await contract.isGasUser(signers[0].address)));
  console.log('getGasUserList: ', (await contract.getGasUserList()));

  tx =  await contract.setAdmins([signers[0].address,signers[1].address], true);
  console.log(tx.hash);
  receipt = await tx.wait();
  console.log(receipt.status);
  console.log('isAdmin: ', (await contract.isAdmin(signers[0].address)));
  console.log('getAdminList: ', (await contract.getAdminList()));

  // tx = await signers[0].sendTransaction({
  //   to: signers[1].address,
  //   value: ethers.utils.parseEther("1") // 1 ether
  // })
  // receipt = await tx.wait();
  // console.log(receipt.status);
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

async function testNodeManager() {

  var encoded = new TextEncoder().encode("Γεια σου κόσμε");
  var decoded = new TextDecoder("utf-8").decode(encoded);
  console.log(decoded);
  const peersObj = [
    [
      [
        bytesToHex(new TextEncoder().encode("0x0361c6591a660424c1a0ed727dcc4190b45c593146a768503ef96d80a489522371")),
        '0x2d3913c12aca0e4a2278f829fb78a682123c0125'
      ],
      [
        '0x3078303262356338366638383139636635313932363437393432653237396435333665316663353363333033316433636439646565636636383266366364666239646233',
        '0x45d53a40ea246bb8ecb1417a7f3ce8bf5dccc6e3'
      ],
      [
        '0x3078303337656439316436643030643132626633653765366231666337636461663262383432363365313430333036643036313131623636663662663237653633363036',
        '0x96775aa16b505734c8aca2cac69c5673c514343a'
      ],
      [
        '0x3078303263303766623764343865616335353961323438336532343964323738343163313863376365356462626266323739366136393633636339636566323763616264',
        '0x258af48e28e4a6846e931ddff8e1cdf8579821e5'
      ]
    ]
  ];
  const peersStr = RLP.encode(peersObj);
  console.log(peersStr);

  // const pubHex = "0x0361c6591a660424c1a0ed727dcc4190b45c593146a768503ef96d80a489522371";
  // console.log("utf8 hex: "+ bytesToHex(new TextEncoder().encode(pubHex)));

  // {"List":[{"PubKey":"0x0361c6591a660424c1a0ed727dcc4190b45c593146a768503ef96d80a489522371","Address":"0x2d3913c12aca0e4a2278f829fb78a682123c0125"},{"PubKey":"0x02b5c86f8819cf5192647942e279d536e1fc53c3031d3cd9deecf682f6cdfb9db3","Address":"0x45d53a40ea246bb8ecb1417a7f3ce8bf5dccc6e3"},{"PubKey":"0x037ed91d6d00d12bf3e7e6b1fc7cdaf2b84263e140306d06111b66f6bf27e63606","Address":"0x96775aa16b505734c8aca2cac69c5673c514343a"},{"PubKey":"0x02c07fb7d48eac559a2483e249d27841c18c7ce5dbbbf2796a6963cc9cef27cabd","Address":"0x258af48e28e4a6846e931ddff8e1cdf8579821e5"}]}
  const peers = "0xf90177f90174f85bb8443078303336316336353931613636303432346331613065643732376463633431393062343563353933313436613736383530336566393664383061343839353232333731942d3913c12aca0e4a2278f829fb78a682123c0125f85bb84430783032623563383666383831396366353139323634373934326532373964353336653166633533633330333164336364396465656366363832663663646662396462339445d53a40ea246bb8ecb1417a7f3ce8bf5dccc6e3f85bb84430783033376564393164366430306431326266336537653662316663376364616632623834323633653134303330366430363131316236366636626632376536333630369496775aa16b505734c8aca2cac69c5673c514343af85bb844307830326330376662376434386561633535396132343833653234396432373834316331386337636535646262626632373936613639363363633963656632376361626494258af48e28e4a6846e931ddff8e1cdf8579821e5";
  console.log(RLP.decode(peers));

  const abi = [{"anonymous":false,"inputs":[{"indexed":false,"internalType":"string","name":"method","type":"string"},{"indexed":false,"internalType":"bytes","name":"input","type":"bytes"},{"indexed":false,"internalType":"address","name":"signer","type":"address"},{"indexed":false,"internalType":"uint64","name":"size","type":"uint64"}],"name":"ConsensusSigned","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"bytes","name":"epoch","type":"bytes"},{"indexed":false,"internalType":"bytes","name":"nextEpoch","type":"bytes"}],"name":"EpochChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"bytes","name":"epoch","type":"bytes"}],"name":"Proposed","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint64","name":"epochID","type":"uint64"},{"indexed":false,"internalType":"bytes","name":"epochHash","type":"bytes"},{"indexed":false,"internalType":"uint64","name":"votedNumber","type":"uint64"},{"indexed":false,"internalType":"uint64","name":"groupSize","type":"uint64"}],"name":"Voted","type":"event"},{"inputs":[],"name":"epoch","outputs":[{"internalType":"bytes","name":"","type":"bytes"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getChangingEpoch","outputs":[{"internalType":"bytes","name":"","type":"bytes"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint64","name":"epochID","type":"uint64"}],"name":"getEpochByID","outputs":[{"internalType":"bytes","name":"","type":"bytes"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"name","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint64","name":"epochID","type":"uint64"}],"name":"proof","outputs":[{"internalType":"bytes","name":"","type":"bytes"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint64","name":"startHeight","type":"uint64"},{"internalType":"bytes","name":"peers","type":"bytes"}],"name":"propose","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint64","name":"epochID","type":"uint64"},{"internalType":"bytes","name":"epochHash","type":"bytes"}],"name":"vote","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"}];
  const address = '0xA4Bf827047a08510722B2d62e668a72FCCFa232C';
  const blockedAccount ="0x5bCA6B1c89e1f4f77b6ad1A0b9b8362c4b316556";
  const newOwner = '0x45d53a40Ea246BB8eCb1417A7f3cE8Bf5DccC6E3';
  
  // const [gov, signer1] = await hre.ethers.getSigners();
  // const tx0 = await gov.sendTransaction({
  //   to: signer1.address,
  //   value: ethers.utils.parseEther("1") // 1 ether
  // })
  // tx0.wait();

   // We get the native contract
   var contract = await hre.ethers.getContractAt("INodeManager", address,(await hre.ethers.getSigners())[3]);

  //  await contract.mint(owner, 1000000000);
  const epochID = 2;
  console.log('contract name: ', (await contract.name()).toString());
  const epoch = await contract.epoch();
  console.log('epoch: ', (await contract.epoch()).toString());
  const decode = RLP.decode(epoch)
  console.log('epoch decode: ', JSON.stringify(decode));
  console.log('getEpochByID: ', (await contract.getEpochByID(epochID)).toString());
  console.log('proof: ', (await contract.proof(epochID)).toString());

  console.log('getEpochListJson: ', (await contract.getEpochListJson(epochID)).toString());
  console.log('getCurrentEpochJson: ', (await contract.getCurrentEpochJson()).toString());
  console.log('getChangingEpochJson: ', (await contract.getChangingEpochJson()).toString());

  // const height = 8500
  // const tx =  await contract.propose(height, peers);
  // console.log(tx.hash); // 0xc64dfd81fadeb7a4ce11340519a06667292630a99b7213c3e041a42e25987264
  // const receipt = await tx.wait();
  // console.log(receipt);

  // const newEpochID = epochID +1;
  // const epochHash =  "0x1802dd8e46f5dbd46d300df58b907645aa6d635665e63095c7af21b5caf8f98a";
  // const tx =  await contract.vote(newEpochID, epochHash);
  // console.log(tx.hash); 
  // const receipt = await tx.wait();
  // console.log(receipt); 

  console.log('getChangingEpoch: ', (await contract.getChangingEpoch()).toString());

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
