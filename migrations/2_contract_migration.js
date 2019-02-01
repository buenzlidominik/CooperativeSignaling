var ProcessData = artifacts.require("./ProcessData.sol");
var Evaluation = artifacts.require("./Evaluation.sol");
var Protocol = artifacts.require("./Protocol.sol");
var IActor = artifacts.require("./IActor.sol");

module.exports = function(deployer) {
  deployer.deploy(Protocol);
};
