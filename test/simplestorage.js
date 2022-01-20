const Factory = artifacts.require("Factory");

const TOKEN0 = "0x4000000000000000000000000000000000000000";
const TOKEN1 = "0x5000000000000000000000000000000000000000";

contract("Factory", accounts => {
  it("...should create a token pair.", async () => {
    const factory = await Factory.deployed();

    let result = await factory.createPair(TOKEN0, TOKEN1);
    let log = result.logs[0];

    assert.equal(log.event, "PairDeployed");
    assert.equal(log.args.token0, TOKEN0);
    assert.equal(log.args.token1, TOKEN1);
  });
});
