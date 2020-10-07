// SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "./DS.sol";
import "./NodeRoleEntryLib.sol";

// This smart contract hold all node role-related items.
// It was made as NodeEntries was starting to get too close to the
// 24KB Ethereum contract size limit.
contract NodeRoleEntries {
  
  /** Array of all node role entries in the network */
  DS.NodeRoleEntry[] public allRoleEntries;

  /** Mapping from node addresses to the corresponding array index in allRoleEntries */
  mapping (uint => uint) addrToRoleEntryIndex;

  /** Number of node role entries in this network */
  uint public numOfNodeRoleEntries;

  // Get array of all DS.NodeRoleEntry instances.
  function getAllNodeRoleEntries() view public returns(DS.NodeRoleEntry[] memory) {
    return allRoleEntries;
  }

  // Add a node to the list of all node entries.
  function addNode(uint _addr) public {
    // Push a new DS.NodeRoleEntry instance onto the array of nodes
    DS.NodeRoleEntry storage nodeRoleEntry = allRoleEntries.push();

    // Initialise the empty node's values
    NodeRoleEntryLib.initNodeStruct(nodeRoleEntry, _addr);
        
    // Add mapping of address to node array index 
    addrToRoleEntryIndex[_addr] = numOfNodeRoleEntries;
    numOfNodeRoleEntries++;
  }

  // Get the index of the node with the given address
  function getNREntryIndex(uint _nodeAddr) view public returns(uint) {
    return addrToRoleEntryIndex[_nodeAddr];
  }
  
  // Get the node with the given address
  function getNREntry(uint _nodeAddr) view public returns(DS.NodeRoleEntry memory) {
    uint nIdx = addrToRoleEntryIndex[_nodeAddr];
    return allRoleEntries[nIdx];
  }
  
  // Assign the sensor role to the given node.
  function assignAsSensor(uint _nodeAddr) public {
    uint nodeIndex = getNREntryIndex(_nodeAddr);
    NodeRoleEntryLib.setAsSensorRole(allRoleEntries[nodeIndex]);
  }
  
  // Assign the controller role to the given node.
  function assignAsController(uint _nodeAddr) public {
    uint nodeIndex = getNREntryIndex(_nodeAddr);
    NodeRoleEntryLib.setAsControllerRole(allRoleEntries[nodeIndex]);
  }
  
  // Assign the actuator role to the given node.
  function assignAsActuator(uint _nodeAddr, string memory _triggerMessage) public {
    uint nodeIndex = getNREntryIndex(_nodeAddr);
    NodeRoleEntryLib.setAsActuatorRole(allRoleEntries[nodeIndex], _triggerMessage);
  }
  
  // Set the given actuator node as triggered.
  function setAsTriggered(uint _nodeAddr) public {
    uint nodeIndex = getNREntryIndex(_nodeAddr);
    NodeRoleEntryLib.setTriggered(allRoleEntries[nodeIndex], true);
  }
  
  // Set the given actuator node as not triggered.
  function setAsNotTriggered(uint _nodeAddr) public {
    uint nodeIndex = getNREntryIndex(_nodeAddr);
    NodeRoleEntryLib.setTriggered(allRoleEntries[nodeIndex], false);
  }
}
