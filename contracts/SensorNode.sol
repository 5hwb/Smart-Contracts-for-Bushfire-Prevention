// SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

contract SensorNode {
  uint public nodeID;                  // ID of the node
  address public nodeAddress;          // Ethereum address of the node
  uint public energyLevel;             // give it when initialising
  uint public numOfOneHopClusterHeads; // init to 1
  bool public isClusterHead;           // init to false
  bool public isMemberNode;           // init to false
  
  address public parentNode;   // parent (cluster head) of this node
  address[] public childNodes; // children of this node (if cluster head)
  address[] public joinRequestNodes; // nodes that have sent join requests to this node
  uint public numOfJoinRequests; // N_T
  address[] public withinRangeNodes; // nodes that are within transmission distance to this node
  
  constructor(uint _id, address _addr, uint _energyLevel) public {
    nodeID = _id;
    nodeAddress = _addr;
    energyLevel = _energyLevel;
  }
  
  function setEnergyLevel(uint level) public {
    energyLevel = level;
  }
  
  function setAsClusterHead() public {
    assert(isMemberNode == false);
    isClusterHead = true;
  }
  
  function setAsMemberNode() public {
    assert(isClusterHead == false);
    isMemberNode = true;
  }
  
  function numOfChildNodes() public view returns (uint) {
    return childNodes.length;
  }
  
  function getJoinRequestNodes() public view returns (address[] memory) {
    return joinRequestNodes;
  }
  
  function numOfWithinRangeNodes() public view returns (uint) {
    return withinRangeNodes.length;
  }
  
  // TODO:
  // make functions to add/get/remove elements in the arrays
}
