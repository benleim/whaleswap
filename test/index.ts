import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { Contract } from "ethers";
import { ethers } from "hardhat";

import { Factory, Pair } from "../typechain";

describe("Factory", function () {
  let factory: Factory;
  let token1: Contract;
  let token2: Contract;
  let owner, addr1, addr2, addr3;

  beforeEach(async function() {
    // Fetch accounts
    [owner, addr1, addr2, addr3] = await ethers.getSigners();

    // Handle deployments
    const FactoryContract = await ethers.getContractFactory("Factory");
    factory = await FactoryContract.deploy();

    const Token1 = await ethers.getContractFactory("TestToken1");
    token1 = await Token1.deploy();
    const Token2 = await ethers.getContractFactory("TestToken1");
    token2 = await Token2.deploy();
  })

  it("Calling createPair() with same token", async function () {
    
  });

  it("Calling createPair() for existing pair", async function () {
    
  });

  it("Calling createPair() should succeed", async function () {
    
  });
});

describe("Pair", function () {
  let factory: Factory;
  let pair: Pair;
  let token1: Contract;
  let token2: Contract;
  let owner: SignerWithAddress, addr1: SignerWithAddress, addr2: SignerWithAddress, addr3: SignerWithAddress;

  beforeEach(async function() {
    // Fetch accounts
    [owner, addr1, addr2, addr3] = await ethers.getSigners();

    // Handle deployments
    const FactoryContract = await ethers.getContractFactory("Factory");
    factory = await FactoryContract.deploy();

    const Token1 = await ethers.getContractFactory("TestToken1");
    token1 = await Token1.deploy();
    const Token2 = await ethers.getContractFactory("TestToken1");
    token2 = await Token2.deploy();

    await factory.createPair(token1.address, token2.address, 50);
    const pairAddress = await factory.getPair(token1.address, token2.address);
    const PairContract = await ethers.getContractFactory('Pair');
    pair = await PairContract.attach(pairAddress);
  })

  it("Calling longTermSwapTokenXtoY() should create long term swap", async function () {
    let ltoAmount = 100000;
    let numberOfIntervals = 100;

    await token1.approve(pair.address, ltoAmount);

    let balanceBefore = await token1.balanceOf(owner.address);
    let response = await pair.longTermSwapTokenXtoY(numberOfIntervals,ltoAmount);
    let balanceAfter = await token1.balanceOf(owner.address);

    expect(balanceBefore - balanceAfter).to.equal(ltoAmount);
    
    let longTermOrder = await pair.getLongTermSwapXtoY(0);
    expect(longTermOrder).to.not.equal(undefined);
  });

  it("Calling longTermSwapTokenYtoX() should create long term swap", async function () {
    
  });
});
