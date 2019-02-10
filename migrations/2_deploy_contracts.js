var EvaluationFactory = artifacts.require("EvaluationFactory");
var StateFactory = artifacts.require("StateFactory");
var Protocol = artifacts.require("Protocol");

module.exports = async function(deployer) {
  await deployer.deploy(EvaluationFactory);
  await deployer.link(EvaluationFactory, StateFactory);
  await deployer.deploy(StateFactory);
  await deployer.link(StateFactory, Protocol);
  await deployer.link(EvaluationFactory, Protocol);
  await deployer.deploy(Protocol);
};