var Protocol = artifacts.require("./Protocol.sol");

module.exports = function(deployer) {
  deployer.deploy(Protocol);
};
