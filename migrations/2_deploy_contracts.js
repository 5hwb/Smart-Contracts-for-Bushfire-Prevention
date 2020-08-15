//var Structs = artifacts.require("Structs");
var NetworkFormation = artifacts.require("NetworkFormation");
var DC = artifacts.require("DC");
var Listo = artifacts.require("Listo");
var QuickSort = artifacts.require("QuickSort");

module.exports = function(deployer) {
  deployer.deploy(NetworkFormation);
  deployer.deploy(DC);
  deployer.link(DC, Listo);
  deployer.deploy(Listo);
  deployer.deploy(QuickSort);
};
