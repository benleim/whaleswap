import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { Contract } from "ethers";
import { ethers } from "hardhat";

import { Factory, Pair } from "../typechain";

describe("Factory", function () {
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

  it("Calling createPair() with same token", async function () {
    const revertReason = 'WHALESWAP: Tokens cannot be the same';
    await expect(factory.createPair(token1.address, token1.address, 100))
      .to.be.revertedWith(revertReason);
  });

  it("Calling createPair() for existing pair", async function () {
    const revertReason = 'WHALESWAP: Pair already exists';
    await expect(factory.createPair(token1.address, token2.address, 100))
      .to.be.revertedWith(revertReason);
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
    let ltoAmount = 100000;
    let numberOfIntervals = 100;

    await token2.approve(pair.address, ltoAmount);

    let balanceBefore = await token2.balanceOf(owner.address);
    let response = await pair.longTermSwapTokenYtoX(numberOfIntervals,ltoAmount);
    let balanceAfter = await token2.balanceOf(owner.address);

    expect(balanceBefore - balanceAfter).to.equal(ltoAmount);
    let longTermOrder = await pair.getLongTermSwapYtoX(0);
    expect(longTermOrder).to.not.equal(undefined);
  });

  it("Calling getCreatedOrders()", async function () {
    // should return nothing before creating long term orders
    let blankOrders = await pair.getCreatedLongTermOrders();
    expect(blankOrders.ordersXtoY.length).to.equal(0);
    expect(blankOrders.ordersYtoX.length).to.equal(0);

    // create long term order x -> y
    let numIntervals = 10, ltoAmount = 100000;
    await token1.approve(pair.address, ltoAmount);
    await pair.longTermSwapTokenXtoY(numIntervals, ltoAmount);

    // confirm fetch for 1 total
    let oneOrder = await pair.getCreatedLongTermOrders();
    expect(oneOrder.ordersXtoY.length).to.equal(1);
    expect(oneOrder.ordersYtoX.length).to.equal(0);

    // create long term order y -> x
    let numIntervals2 = 15, ltoAmount2 = 200000;
    await token2.approve(pair.address, ltoAmount2);
    await pair.longTermSwapTokenYtoX(numIntervals2, ltoAmount2);

    // confirm fetch for 2 total
    let twoOrders = await pair.getCreatedLongTermOrders();
    expect(twoOrders.ordersXtoY.length).to.equal(1);
    expect(twoOrders.ordersYtoX.length).to.equal(1);
  });

  it("Mint & burn liquidity tokens - single LP", async function() {
    await token1.approve(pair.address, 1000);
    await token2.approve(pair.address, 1000);

    let balanceBefore0 =await token1.balanceOf(owner.address);
    let balanceBefore1 = await token2.balanceOf(owner.address);

    let mintLiquidity = await pair.mint(owner.address, 1000, 1000);
    let redeemLiquidity = await pair.burn(owner.address);

    let balanceAfter0 = await token1.balanceOf(owner.address);
    let balanceAfter1 = await token2.balanceOf(owner.address);

    expect(balanceAfter0).to.equal(balanceBefore0);
    expect(balanceAfter1).to.equal(balanceBefore1);
  });

  it("OrderPool executeLongTermOrders()", async function() {
    await pair.executeLongTermOrders();

    const blocks = 150;
    for (let i = 0; i < blocks; i++) {
      await ethers.provider.send('evm_mine',[]);
    }
 
    await pair.executeLongTermOrders();
  });

  it("OrderPool blockrate should change on expiration", async function() {
    
  });
});
