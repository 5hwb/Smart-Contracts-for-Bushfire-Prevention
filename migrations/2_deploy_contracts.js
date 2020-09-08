//var Structs = artifacts.require("Structs");
var NetworkFormation = artifacts.require("NetworkFormation");
var IA = artifacts.require("IA");
var SensorNode = artifacts.require("SensorNode");
var Listo = artifacts.require("Listo");
var QuickSort = artifacts.require("QuickSort");
var QuickSortContract = artifacts.require("QuickSortContract");

module.exports = function(deployer) {
  deployer.deploy(IA);
  deployer.link(IA, Listo);
  deployer.link(IA, SensorNode);
  deployer.link(IA, NetworkFormation);

  deployer.deploy(QuickSort);
  deployer.link(QuickSort, SensorNode);
  deployer.link(QuickSort, NetworkFormation);
  deployer.link(QuickSort, QuickSortContract);

  deployer.deploy(SensorNode);
  deployer.link(SensorNode, NetworkFormation);

  deployer.deploy(Listo);
  deployer.deploy(NetworkFormation);
  deployer.deploy(QuickSortContract);
};
