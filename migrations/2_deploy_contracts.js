//var Structs = artifacts.require("Structs");
var NetworkFormation = artifacts.require("NetworkFormation");
var NodeRoleEntries = artifacts.require("NodeRoleEntries");
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
  deployer.link(SensorNode2, NodeRoleEntries);

  deployer.deploy(NetworkFormation);
  deployer.deploy(NodeRoleEntries);
  deployer.deploy(QuickSortContract);
  
  var networkFormation, nodeRoleEntries;
  deployer.then(function() {
    // Get the deployed instance of NetworkFormation
    console.log("getting deployed instance of NetworkFormation...");
    return NetworkFormation.deployed();
  }).then(function(instance) {
    networkFormation = instance;
    // Get the deployed instance of NodeRoleEntries
    console.log("getting deployed instance of NodeRoleEntries...");
    return NodeRoleEntries.deployed();
  }).then(function(instance) {
    nodeRoleEntries = instance;
    // Set NodeRoleEntries instance
    console.log("setting NodeRoleEntries instance...");
    return networkFormation.setNodeRoleEntries(nodeRoleEntries.address);
  });
};
