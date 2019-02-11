var EvaluationFactory = artifacts.require("EvaluationFactory");
var Protocol = artifacts.require("Protocol");

module.exports = async function(deployer) {
  await deployer.deploy(EvaluationFactory);
  await deployer.link(EvaluationFactory, Protocol);
  await deployer.deploy(Protocol);
};