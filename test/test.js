const { expect } = require("chai");
const { ethers, waffe } = require("hardhat");

describe("NFT", function () {

  var NFT;
  var owner;
  var whiteListUser0;
  var whiteListUser1;
  var whiteListUser2;

  var VIPUser0;
  var VIPUser1;
  var VIPUser2;

  beforeEach("deploy", async function () {
    const Contract = await ethers.getContractFactory("NFT");
    const _NFT = await Contract.deploy("My NFT", "NFT");
    await _NFT.deployed();
    await _NFT.setCurrentStage(1);
    NFT = _NFT;

    const [_owner, addr1, addr2, addr3, addr4, addr5, addr6] = await ethers.getSigners();
    await NFT.addWhiteList(_owner.address);
    await NFT.addWhiteList(addr1.address);
    await NFT.addWhiteList(addr2.address);
    await NFT.addWhiteList(addr3.address);

    await NFT.addVIP(_owner.address);
    await NFT.addVIP(addr4.address);
    await NFT.addVIP(addr5.address);
    await NFT.addVIP(addr6.address);

    owner = _owner;
    whiteListUser0 = addr1;
    whiteListUser1 = addr2;
    whiteListUser2 = addr3;
    VIPUser0 = addr4;
    VIPUser1 = addr5;
    VIPUser2 = addr6;

  });

  it("check base info", async function () {
    expect(await NFT.name()).to.equal("My NFT");
    expect(await NFT.symbol()).to.equal("NFT");
  });

  it("check set current stage", async function () {
    await NFT.setCurrentStage(2)
    
  });

  it("check whitelist User", async function() {

    // mint
    await NFT.connect(whiteListUser0).mintNFTs("NFT1","image_url", "gold", 1, 2, 3, 1);
    expect(await NFT.ownerOf(0)).to.equal(whiteListUser0.address);
    expect(NFT.connect(VIPUser0).mintNFTs("NFT2","image_url", "gold", 1, 2, 3, 1)).to.be.revertedWith("is missing role");

    // transfer
    await NFT.connect(whiteListUser0).transferFrom(whiteListUser0.address, whiteListUser1.address, 0);
    expect(await NFT.ownerOf(0)).to.equal(whiteListUser1.address);
    expect( NFT.connect(whiteListUser0).transferFrom(whiteListUser0.address, VIPUser0.address, 0)).to.be.revertedWith("he/she is not whitelist user");

  });

  it("check VIP user", async function() {

    // mint
    await NFT.mintVIPNFTs("NFT1","image_url", "gold", 1, 2, 3, 1);
    expect(await NFT.ownerOf(0)).to.equal(owner.address);
    expect(NFT.connect(whiteListUser2).mintVIPNFTs("NFT2","image_url", "gold", 1, 2, 3, 1)).to.be.revertedWith("is missing role");

    // transfer
    await NFT.transferFrom(owner.address, VIPUser0.address, 0);
    expect(await NFT.ownerOf(0)).to.equal(VIPUser0.address);
    expect( NFT.connect(VIPUser0).transferFrom(VIPUser0.address, whiteListUser0.address, 0)).to.be.revertedWith("he/she is not vip");

  });

  it("check stage", async function() {

    await NFT.mintNFTs("NFT1","https://ipfs.io/ipfs/QmWGAFtzyzB6A6gYMnb6838hysHuT2rcV8B98Gmj4T4pyY/24.json", "gold", 1, 2, 3, 1);
    await NFT.mintNFTs("NFT1","https://ipfs.io/ipfs/QmWGAFtzyzB6A6gYMnb6838hysHuT2rcV8B98Gmj4T4pyY/24.json", "gold", 1, 2, 3, 1);
    await NFT.transferFrom(owner.address, whiteListUser0.address, 1);
    // console.log(await NFT.ownerOf(1));
    // expect().to.throw();
  });

  it("check mint", async function() {

    await NFT.mintNFTs("NFT1","https://ipfs.io/ipfs/QmWGAFtzyzB6A6gYMnb6838hysHuT2rcV8B98Gmj4T4pyY/24.json", "gold", 1, 2, 3, 1);

  });

  it("check mint limit", async function() {
    await NFT.mintNFTs("NFT1","https://ipfs.io/ipfs/QmWGAFtzyzB6A6gYMnb6838hysHuT2rcV8B98Gmj4T4pyY/24.json", "gold", 1, 2, 3, 4);
  });

  it("check mint limit", async function() {
    await NFT.mintNFTs("NFT1","https://ipfs.io/ipfs/QmWGAFtzyzB6A6gYMnb6838hysHuT2rcV8B98Gmj4T4pyY/24.json", "gold", 1, 2, 3, 2);
    await NFT.connect(addr1).mintNFTs("NFT1","https://ipfs.io/ipfs/QmWGAFtzyzB6A6gYMnb6838hysHuT2rcV8B98Gmj4T4pyY/24.json", "gold", 1, 2, 3, 2);
    
    await NFT.transferFrom(owner.address, addr2.address, 0);
    await NFT.transferFrom(owner.address, addr2.address, 1);
    await NFT.transferFrom(addr1.address, addr2.address, 2);

  });


});

describe("NFT", function() {

});