// SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

contract SensorNode {
  uint public nodeID;         // ID of the node
  address public nodeAddress; // Ethereum address of the node
  // TODO eventually: Make the energy level based on the battery current and voltage available 
  uint public energyLevel;    // give it when initialising.
  uint public networkLevel;          // Tree level this node is located at
  uint public numOfOneHopClusterHeads; // init to 1
  bool public isClusterHead;           // init to false
  bool public isMemberNode;            // init to false
  
  address public parentNode;         // parent (cluster head) of this node
  address[] public childNodes;       // children of this node (if cluster head)
  address[] public joinRequestNodes; // nodes that have sent join requests to this node
  uint public numOfJoinRequests;     // N_T
  address[] public withinRangeNodes; // nodes that are within transmission distance to this node
  
  constructor(uint _id, address _addr, uint _energyLevel) public {
    nodeID = _id;
    nodeAddress = _addr;
    energyLevel = _energyLevel;
  }
  
  ////////////////////////////////////////
  // SETTER FUNCTIONS
  ////////////////////////////////////////
  
  function setEnergyLevel(uint eLevel) public {
    energyLevel = eLevel;
  }
  
  function setNetworkLevel(uint nLevel) public {
    networkLevel = nLevel;
  }
  
  function setAsClusterHead() public {
    assert(isMemberNode == false);
    isClusterHead = true;
  }
  
  function setAsMemberNode() public {
    assert(isClusterHead == false);
    isMemberNode = true;
  }
  
  function addJoinRequestNode(address addr) public {
    joinRequestNodes.push(addr);
    numOfJoinRequests++;
  }
  
  ////////////////////////////////////////
  // childNodes GETTER FUNCTIONS
  ////////////////////////////////////////
  
  function numOfChildNodes() public view returns (uint) {
    return childNodes.length;
  }
  
  ////////////////////////////////////////
  // joinRequestNodes GETTER FUNCTIONS
  ////////////////////////////////////////
  
  function getJoinRequestNodes() public view returns (address[] memory) {
    return joinRequestNodes;
  }
  
  ////////////////////////////////////////
  // withinRangeNodes GETTER FUNCTIONS
  ////////////////////////////////////////
  
  function addWithinRangeNode(address addr) public {
    withinRangeNodes.push(addr);
  }
  
  function getWithinRangeNodes() public view returns (address[] memory) {
    return withinRangeNodes;
  }
  
  function numOfWithinRangeNodes() public view returns (uint) {
    return withinRangeNodes.length;
  }
  
  // TODO:
  // make functions to add/get/remove elements in the arrays
}
