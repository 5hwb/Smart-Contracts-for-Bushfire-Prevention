//var Structs = artifacts.require("Structs");
var NetworkFormation = artifacts.require("NetworkFormation");
var NetworkFormation2 = artifacts.require("NetworkFormation2");
var IA = artifacts.require("IA");
var SensorNode = artifacts.require("SensorNode");
var SensorNode2 = artifacts.require("SensorNode2");
var QuickSort = artifacts.require("QuickSort");
var QuickSortContract = artifacts.require("QuickSortContract");

module.exports = function(deployer) {
  deployer.deploy(IA);
  deployer.link(IA, SensorNode);
  deployer.link(IA, NetworkFormation);

  deployer.deploy(QuickSort);
  deployer.link(QuickSort, SensorNode);
  deployer.link(QuickSort, NetworkFormation);
  deployer.link(QuickSort, QuickSortContract);

  deployer.deploy(SensorNode);
  deployer.link(SensorNode, NetworkFormation);

  deployer.deploy(SensorNode2);
  deployer.link(SensorNode2, NetworkFormation2);

  deployer.deploy(NetworkFormation);
  deployer.deploy(NetworkFormation2);
  deployer.deploy(QuickSortContract);
  
  var networkFormation, networkFormation2;
  deployer.then(function() {
    // Get the deployed instance of NetworkFormation
    console.log("getting deployed instance of NetworkFormation...");
    return NetworkFormation.deployed();
  }).then(function(instance) {
    networkFormation = instance;
    // Get the deployed instance of NetworkFormation2
    console.log("getting deployed instance of NetworkFormation2...");
    return NetworkFormation2.deployed();
  }).then(function(instance) {
    networkFormation2 = instance;
    // Set NetworkFormation2 instance
    console.log("setting NetworkFormation2 instance...");
    return networkFormation.setNetworkFormation2(networkFormation2.address);
  });
};
