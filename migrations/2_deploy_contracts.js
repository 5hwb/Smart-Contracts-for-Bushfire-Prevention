var NetworkFormation = artifacts.require("NetworkFormation");
var QuickSort = artifacts.require("QuickSort");

module.exports = function(deployer) {
  deployer.deploy(NetworkFormation);
  deployer.deploy(QuickSort);
};