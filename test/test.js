const { expect } = require("chai");
const { ethers, waffe } = require("hardhat");

describe("NFT", function () {

  var NFT;
  beforeEach("deploy", async function () {
    const Contract = await ethers.getContractFactory("NFT");
    const _NFT = await Contract.deploy("My NFT", "NFT");
    await _NFT.deployed();
    await _NFT.setCurrentStage(1);
    NFT = _NFT;
  });

  it("check base info", async function () {

    expect(await NFT.name()).to.equal("My NFT");
    expect(await NFT.symbol()).to.equal("NFT");

    // const setGreetingTx = await greeter.setGreeting("Hola, mundo!");

    // // wait until the transaction is mined
    // await setGreetingTx.wait();

    // expect(await greeter.greet()).to.equal("Hola, mundo!");
  });

  it("check whitelist User", async function() {
    const [owner, addr1] = await ethers.getSigners();
    await NFT.addWhiteList(owner.address);
    await NFT.addWhiteList(addr1.address);

    await NFT.createNFTs("https://ipfs.io/ipfs/QmWGAFtzyzB6A6gYMnb6838hysHuT2rcV8B98Gmj4T4pyY/24.json", 1, 1);
    
    await NFT.transferFrom(owner.address, addr1.address, 0);

  });

  it("check VIP user", async function() {
    const [owner, addr1] = await ethers.getSigners();
    await NFT.addVIP(owner.address);
    await NFT.addVIP(addr1.address);

    await NFT.createVIPNFTs("https://ipfs.io/ipfs/QmWGAFtzyzB6A6gYMnb6838hysHuT2rcV8B98Gmj4T4pyY/24.json", 1);

    await NFT.transferFrom(owner.address, addr1.address, 0);
  });

  it("check stage", async function() {
    const [owner, addr1] = await ethers.getSigners();
    await NFT.addWhiteList(owner.address);
    await NFT.addWhiteList(addr1.address);

    await NFT.createNFTs("https://ipfs.io/ipfs/QmWGAFtzyzB6A6gYMnb6838hysHuT2rcV8B98Gmj4T4pyY/24.json", 1, 1);
    await NFT.createNFTs("https://ipfs.io/ipfs/QmWGAFtzyzB6A6gYMnb6838hysHuT2rcV8B98Gmj4T4pyY/24.json", 2, 1);
    
    expect(await NFT.transferFrom(owner.address, addr1.address, 1)).to.throw();
  });

  it("check purchase limit", async function() {
    const [owner, addr1] = await ethers.getSigners();
    await NFT.addWhiteList(owner.address);
    await NFT.addWhiteList(addr1.address);

    await NFT.createNFTs("https://ipfs.io/ipfs/QmWGAFtzyzB6A6gYMnb6838hysHuT2rcV8B98Gmj4T4pyY/24.json", 1, 4);
    
    await NFT.transferFrom(owner.address, addr1.address, 0);
    await NFT.transferFrom(owner.address, addr1.address, 1);
    await NFT.transferFrom(owner.address, addr1.address, 2);

  });



});

describe("NFT", function() {

});