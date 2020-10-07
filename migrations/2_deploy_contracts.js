//var Structs = artifacts.require("Structs");
var NodeEntries = artifacts.require("NodeEntries");
var NodeRoleEntries = artifacts.require("NodeRoleEntries");
var IA = artifacts.require("IA");
var NodeEntryLib = artifacts.require("NodeEntryLib");
var NodeRoleEntryLib = artifacts.require("NodeRoleEntryLib");
var QuickSort = artifacts.require("QuickSort");
var QuickSortContract = artifacts.require("QuickSortContract");

module.exports = function(deployer) {
  deployer.deploy(IA);
  deployer.link(IA, NodeEntryLib);
  deployer.link(IA, NodeEntries);

  deployer.deploy(QuickSort);
  deployer.link(QuickSort, NodeEntryLib);
  deployer.link(QuickSort, NodeEntries);
  deployer.link(QuickSort, QuickSortContract);

  deployer.deploy(NodeEntryLib);
  deployer.link(NodeEntryLib, NodeEntries);

  deployer.deploy(NodeRoleEntryLib);
  deployer.link(NodeRoleEntryLib, NodeRoleEntries);

  deployer.deploy(NodeEntries);
  deployer.deploy(NodeRoleEntries);
  deployer.deploy(QuickSortContract);
  
  var nodeEntries, nodeRoleEntries;
  deployer.then(function() {
    // Get the deployed instance of NodeEntries
    console.log("getting deployed instance of NodeEntries...");
    return NodeEntries.deployed();
  }).then(function(instance) {
    nodeEntries = instance;
    // Get the deployed instance of NodeRoleEntries
    console.log("getting deployed instance of NodeRoleEntries...");
    return NodeRoleEntries.deployed();
  }).then(function(instance) {
    nodeRoleEntries = instance;
    // Set NodeRoleEntries instance
    console.log("setting NodeRoleEntries instance...");
    return nodeEntries.setNodeRoleEntries(nodeRoleEntries.address);
  });
};
