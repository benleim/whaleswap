const SimpleStorage = artifacts.require("SimpleStorage");
const TutorialToken = artifacts.require("TutorialToken");
const ComplexStorage = artifacts.require("ComplexStorage");
const SimpleToken1 = artifacts.require("SimpleToken1");
const SimpleToken2 = artifacts.require("SimpleToken2");

module.exports = function(deployer) {
  deployer.deploy(SimpleStorage);
  deployer.deploy(TutorialToken);
  deployer.deploy(ComplexStorage);
  deployer.deploy(SimpleToken1);
  deployer.deploy(SimpleToken2);
};
