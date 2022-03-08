const { expect } = require("chai");
const { ethers, waffe } = require("hardhat");

describe("NFT", function () {

  var NFT;
  var owner;
  var wlu0;
  var wlu1;
  var wlu2;

  var vu0;
  var vu1;
  var vu2;

  var nu;

  beforeEach("deploy", async function () {
    const Contract = await ethers.getContractFactory("NFT");
    const _NFT = await Contract.deploy("My NFT", "NFT");
    await _NFT.deployed();
    await _NFT.setCurrentStage(1);
    NFT = _NFT;

    const [_owner, addr1, addr2, addr3, addr4, addr5, addr6, addr7] = await ethers.getSigners();
    await NFT.addWhiteList(_owner.address);
    await NFT.addWhiteList(addr1.address);
    await NFT.addWhiteList(addr2.address);
    await NFT.addWhiteList(addr3.address);

    await NFT.addVIP(_owner.address);
    await NFT.addVIP(addr4.address);
    await NFT.addVIP(addr5.address);
    await NFT.addVIP(addr6.address);

    owner = _owner;
    wlu0 = addr1;
    wlu1 = addr2;
    wlu2 = addr3;
    vu0 = addr4;
    vu1 = addr5;
    vu2 = addr6;
    nu = addr7;

  });

  it("check base info", async function () {
    expect(await NFT.name()).to.equal("My NFT");
    expect(await NFT.symbol()).to.equal("NFT");
  });

  it("check set current stage", async function () {
    await NFT.setCurrentStage(2)
    await expect(NFT.setCurrentStage(4)).to.be.revertedWith("it's a unknown stage");

    // whitelist cannot change stage
    await expect(NFT.connect(wlu1).setCurrentStage(1)).to.be.revertedWith("caller is not the owner");
    // vip user cannot change stage
    await expect(NFT.connect(vu0).setCurrentStage(1)).to.be.revertedWith("caller is not the owner");

  });

  it("check whitelist User", async function() {

    // mint
    await NFT.connect(wlu0).mintNFTs("NFT1","image_url", "gold", 1, 2, 3, 1);
    expect(await NFT.ownerOf(0)).to.equal(wlu0.address);
    await expect(NFT.connect(vu0).mintNFTs("NFT2","image_url", "gold", 1, 2, 3, 1)).to.be.revertedWith("is missing role");

    // transfer
    await NFT.connect(wlu0).transferFrom(wlu0.address, wlu1.address, 0);
    expect(await NFT.ownerOf(0)).to.equal(wlu1.address);
    await expect(NFT.connect(wlu0).transferFrom(wlu0.address, vu0.address, 0)).to.be.revertedWith("reciver is not whitelist user");

  });

  it("check VIP user", async function() {

    // mint
    await NFT.mintVIPNFTs("NFT1","image_url", "gold", 1, 2, 3, 1);
    expect(await NFT.ownerOf(0)).to.equal(owner.address);
    await expect(NFT.connect(wlu2).mintVIPNFTs("NFT2","image_url", "gold", 1, 2, 3, 1)).to.be.revertedWith("is missing role");

    // transfer
    await NFT.transferFrom(owner.address, vu0.address, 0);
    expect(await NFT.ownerOf(0)).to.equal(vu0.address);
    await expect( NFT.connect(vu0).transferFrom(vu0.address, wlu0.address, 0)).to.be.revertedWith("reciver is not vip");

  });

  it("check stage", async function() {

    // stage 1
    await NFT.setCurrentStage(1);
    // stage 1 only mint 1 token
    await expect(NFT.mintNFTs("NFT1","image_url", "gold", 1, 2, 3, 2)).to.be.revertedWith("cannot mint more");
    await NFT.mintNFTs("NFT1","image_url", "gold", 1, 2, 3, 1);
    await expect(NFT.mintNFTs("NFT1","image_url", "gold", 1, 2, 3, 1)).to.be.revertedWith("cannot mint more");

    await NFT.transferFrom(owner.address, wlu0.address, 0);
    await expect(NFT.connect(wlu0).mintNFTs("NFT1","image_url", "gold", 1, 2, 3, 1)).to.be.revertedWith("cannot mint more");
    
    // stage 2,
    await NFT.setCurrentStage(2); 
    // stage 2 only mint 2 token
    await expect(NFT.connect(wlu1).mintNFTs("NFT1","image_url", "gold", 1, 2, 3, 3)).to.be.revertedWith("cannot mint more");
    await NFT.connect(wlu1).mintNFTs("NFT1","image_url", "gold", 1, 2, 3, 2);


    await NFT.connect(wlu1).transferFrom(wlu1.address, wlu2.address, 1);
    await NFT.connect(wlu1).transferFrom(wlu1.address, wlu2.address, 2);
    await expect(NFT.connect(wlu2).mintNFTs("NFT1","image_url", "gold", 1, 2, 3, 1)).to.be.revertedWith("cannot mint more");

    // stage 3,
    await NFT.setCurrentStage(3); 
    // stage 3 has no limit
    await NFT.connect(wlu2).mintNFTs("NFT1","image_url", "gold", 1, 2, 3, 200);
    expect(await NFT.ownerOf(200)).to.equal(wlu2.address);


  });

  it("check transfer limit", async function() {

    await NFT.setCurrentStage(2);
    await NFT.mintNFTs("NFT1","image_url", "gold", 1, 2, 3, 2);
    await NFT.connect(wlu0).mintNFTs("NFT1","image_url", "gold", 1, 2, 3, 1);
    
    await NFT.transferFrom(owner.address, wlu0.address, 0);
    await expect(NFT.transferFrom(owner.address, wlu0.address, 1)).to.be.revertedWith("revicer are over purchase limited.");

  });


});
