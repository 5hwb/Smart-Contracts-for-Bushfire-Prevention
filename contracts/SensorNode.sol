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
  
  SensorNode public parentNode;         // parent (cluster head) of this node
  SensorNode[] public childNodes;       // children of this node (if cluster head)
  SensorNode[] public joinRequestNodes; // nodes that have sent join requests to this node
  uint public numOfJoinRequests;     // N_T
  uint256[] public withinRangeNodes; // nodes that are within transmission distance to this node
  
  // Simulate the sensor reading process
  // (for now, just use an uint. Change to a struct with more details (timestamp, originating node etc) later
  uint256[] public sensorReadings;
  
  constructor(uint _id, uint256 _addr, uint _energyLevel) public {
    nodeID = _id;
    nodeAddress = _addr;
    energyLevel = _energyLevel;
    networkLevel = 0; // invalid value for now
  }
  
  ////////////////////////////////////////
  // Simulate receiving input from sensors!
  ////////////////////////////////////////
  
  function readSensorInput(uint256[] memory sReadings) public {
    // Add incoming sensor readings to this node's list of sensor readings
    for (uint i = 0; i < sReadings.length; i++) {
      sensorReadings.push(sReadings[i]);
    }
  
    // Call this again for parent node (intended effect: send the values all the way up to the sink nodes)
    if (address(parentNode) != 0x0000000000000000000000000000000000000000) {
      parentNode.readSensorInput(sensorReadings);
    }
  }
  
  function getSensorReadings() public returns(uint256[] memory) {
    return sensorReadings;
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
  
  function setParentNode(SensorNode addr) public {
    parentNode = addr;
  }
  
  function addJoinRequestNode(SensorNode addr) public {
    joinRequestNodes.push(addr);
    numOfJoinRequests++;
  }

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
  
  function getJoinRequestNodes() public view returns (SensorNode[] memory) {
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
