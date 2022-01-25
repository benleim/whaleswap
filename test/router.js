const Router = artifacts.require("Router");
const Factory = artifacts.require("Factory");
const TestToken1 = artifacts.require("TestToken1");
const TestToken2 = artifacts.require("TestToken2");

contract("Factory", accounts => {
  it("...should successfully add liquidity.", async () => {
    const factory = await Factory.deployed();
    const router = await Router.deployed();
    const token1 = await TestToken1.deployed();
    const token2 = await TestToken2.deployed();

    // Create test token pair
    let cpResult = await factory.createPair(token1.address, token2.address);
    let log = cpResult.logs[0];

    assert.equal(log.event, "PairDeployed");

    // Test adding liquidity
    await debug(router.addLiquidity(token1.address, token2.address, 10000, 10000, accounts[0]));
    console.log(alResult);
  });
});
