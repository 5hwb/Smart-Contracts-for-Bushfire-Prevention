var Structs = artifacts.require("Structs");
var NetworkFormation = artifacts.require("NetworkFormation");
var QuickSort = artifacts.require("QuickSort");

module.exports = function(deployer) {
  deployer.deploy(Structs);
  deployer.deploy(NetworkFormation);
  deployer.deploy(QuickSort);
};
