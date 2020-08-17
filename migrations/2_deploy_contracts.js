//var Structs = artifacts.require("Structs");
var NetworkFormation = artifacts.require("NetworkFormation");
var IA = artifacts.require("IA");
var Listo = artifacts.require("Listo");
var QuickSort = artifacts.require("QuickSort");

module.exports = function(deployer) {
  deployer.deploy(IA);
  deployer.link(IA, Listo);
  deployer.link(IA, NetworkFormation);
  deployer.deploy(Listo);
  deployer.deploy(NetworkFormation);
  deployer.deploy(QuickSort);
};
