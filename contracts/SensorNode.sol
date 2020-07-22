// SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

contract SensorNode {
  uint public nodeID;         // ID of the node
  uint256 public nodeAddress; // Address of the node
  // TODO eventually: Make the energy level based on the battery current and voltage available 
  uint public energyLevel;    // give it when initialising.
  uint public networkLevel;          // Tree level this node is located at
  uint public numOfOneHopClusterHeads; // init to 1
  bool public isClusterHead;           // init to false
  bool public isMemberNode;            // init to false
  
  uint256 public parentNode;         // parent (cluster head) of this node
  uint256[] public childNodes;       // children of this node (if cluster head)
  uint256[] public joinRequestNodes; // nodes that have sent join requests to this node
  uint public numOfJoinRequests;     // N_T
  uint256[] public withinRangeNodes; // nodes that are within transmission distance to this node
  
  constructor(uint _id, uint256 _addr, uint _energyLevel) public {
    nodeID = _id;
    nodeAddress = _addr;
    energyLevel = _energyLevel;
    networkLevel = 0; // invalid value for now
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
  
  function setParentNode(uint256 addr) public {
    parentNode = addr;
  }
  
  function addJoinRequestNode(uint256 addr) public {
    joinRequestNodes.push(addr);
    numOfJoinRequests++;
  }

  // TODO: find out the CAUSE of this
  // STRANGE BUG: adding this function causes the sort test case to FAIL!
  // ALSO: in testSortNodes() in TestNetworkFormation.sol,
  // commenting out the last 2 addNode() calls gets rid of the error!
  // ALSO: changing all address types from 'address' to 'uint256' fixes the problem.
  function addWithinRangeNode(uint256 addr) public {
    withinRangeNodes.push(addr);
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
  
  function getJoinRequestNodes() public view returns (uint256[] memory) {
    return joinRequestNodes;
  }
  
  ////////////////////////////////////////
  // withinRangeNodes GETTER FUNCTIONS
  ////////////////////////////////////////
  
  function getWithinRangeNodes() public view returns (uint256[] memory) {
    return withinRangeNodes;
  }
  
  function numOfWithinRangeNodes() public view returns (uint) {
    return withinRangeNodes.length;
  }
  
  // TODO:
  // make functions to add/get/remove elements in the arrays
}
