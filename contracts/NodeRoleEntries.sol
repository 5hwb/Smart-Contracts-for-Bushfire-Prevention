// SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "./DS.sol";
import "./SensorNode2.sol";

// This smart contract hold all node role-related items.
// It was made as NetworkFormation was starting to get too close to the
// 24KB Ethereum contract size limit.
contract NodeRoleEntries {
  
  // Array of all node role entries in the network
  DS.NodeRoleEntry[] public allNodes2;
  mapping (uint => uint) addrToNodeIndex2; // node addresses -> node array index

  uint public numOfNodeRoleEntries; // Number of node role entries in this network

  // Get array of all DS.NodeRoleEntry instances.
  function getAllNodeRoleEntrys() view public returns(DS.NodeRoleEntry[] memory) {
    return allNodes2;
  }

  // Add a node to the list of all sensor nodes.
  function addNode(uint _addr) public {
    // Push a new DS.NodeRoleEntry instance onto the array of nodes
    DS.NodeRoleEntry storage nodeRoleEntry = allNodes2.push();

    // Initialise the empty node's values
    SensorNode2.initNodeStruct(nodeRoleEntry, _addr);
        
    // Add mapping of address to node array index 
    addrToNodeIndex2[_addr] = numOfNodeRoleEntries;
    numOfNodeRoleEntries++;
  }

  // Get the index of the node with the given address
  function getNodeRoleEntryIndex(uint _nodeAddr) view public returns(uint) {
    return addrToNodeIndex2[_nodeAddr];
  }
  
  // Get the node with the given address
  function getNodeRoleEntryAsMemory(uint _nodeAddr) view public returns(DS.NodeRoleEntry memory) {
    uint nIdx = addrToNodeIndex2[_nodeAddr];
    return allNodes2[nIdx];
  }
  
  // Assign the sensor role to the given node.
  function assignAsSensor(uint _nodeAddr) public {
    uint nodeIndex = getNodeRoleEntryIndex(_nodeAddr);
    SensorNode2.setAsSensorRole(allNodes2[nodeIndex]);
  }
  
  // Assign the controller role to the given node.
  function assignAsController(uint _nodeAddr) public {
    uint nodeIndex = getNodeRoleEntryIndex(_nodeAddr);
    SensorNode2.setAsControllerRole(allNodes2[nodeIndex]);
  }
  
  // Assign the actuator role to the given node.
  function assignAsActuator(uint _nodeAddr, string memory _triggerMessage) public {
    uint nodeIndex = getNodeRoleEntryIndex(_nodeAddr);
    SensorNode2.setAsActuatorRole(allNodes2[nodeIndex], _triggerMessage);
  }
  
  // Set the given actuator node as triggered.
  function setAsTriggered(uint _nodeAddr) public {
    uint nodeIndex = getNodeRoleEntryIndex(_nodeAddr);
    SensorNode2.setTriggered(allNodes2[nodeIndex], true);
  }
  
  // Set the given actuator node as not triggered.
  function setAsNotTriggered(uint _nodeAddr) public {
    uint nodeIndex = getNodeRoleEntryIndex(_nodeAddr);
    SensorNode2.setTriggered(allNodes2[nodeIndex], false);
  }
}
