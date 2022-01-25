const Factory = artifacts.require("Factory");
const Router = artifacts.require("Router");
const TestToken1 = artifacts.require("TestToken1");
const TestToken2 = artifacts.require("TestToken2");

module.exports = function(deployer) {
  // AMM contracts
  deployer.deploy(Factory).then(() => {
    return deployer.deploy(Router, Factory.address)
  });

  // Tokens
  deployer.deploy(TestToken1);
  deployer.deploy(TestToken2);
};
