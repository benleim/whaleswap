const SimpleStorage = artifacts.require("SimpleStorage");
const ComplexStorage = artifacts.require("ComplexStorage");
const SimpleToken1 = artifacts.require("SimpleToken1");
const SimpleToken2 = artifacts.require("SimpleToken2");
const Factory = artifacts.require("Factory");

module.exports = function(deployer) {
  deployer.deploy(SimpleStorage);
  deployer.deploy(ComplexStorage);

  // Test Tokens
  deployer.deploy(SimpleToken1);
  deployer.deploy(SimpleToken2);

  // AMM contracts
  deployer.deploy(Factory, "0x0000000000000000000000000000000000000000")
};
