const Factory = artifacts.require("Factory");

module.exports = function(deployer) {
  // AMM contracts
  deployer.deploy(Factory)
};
