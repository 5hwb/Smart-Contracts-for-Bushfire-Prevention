// SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "./DS.sol";

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
  
  // Simulate receiving a beacon from a cluster head 
  bool public hasReceivedBeacon;      // Self-descriptory bool flag
  SensorNode public beaconSenderNode; // The node that sent the beacon
  
  // Simulate the sensor reading process
  DS.SensorReading[] public sensorReadings;    // Array of SensorReading structs
  mapping (uint => uint) readingToStructIndex; // Sensor reading -> SensorReading array index
  uint numOfReadings; // Number of sensor readings held by this node

  // Events
  event LogString(string str);

  // SensorNode constructor
  constructor(uint _id, uint256 _addr, uint _energyLevel) public {
    nodeID = _id;
    nodeAddress = _addr;
    energyLevel = _energyLevel;
    networkLevel = 0; // invalid value for now
    hasReceivedBeacon = false;
    
    // Add a dummy 'null' reading as the 1st element to make it easy to check 
    // if a SensorReading is read already 
    sensorReadings.push(DS.SensorReading(0, false));
  }
  
  ////////////////////////////////////////
  // Simulate receiving beacon from cluster head!
  ////////////////////////////////////////
  
  function receiveBeacon(SensorNode cHead) public {
    hasReceivedBeacon = true;
    beaconSenderNode = cHead;
  }
  
  ////////////////////////////////////////
  // Simulate receiving input from sensors!
  ////////////////////////////////////////
  function readSensorInput(DS.SensorReading[] memory sReadings) public {
    
    // Add incoming sensor readings to this node's list of sensor readings
    for (uint i = 0; i < sReadings.length; i++) {

      // Check if the sensor reading has already been added before adding it.
      // Ignore duplicates and null '0' readings
      uint sReadingIndex = readingToStructIndex[sReadings[i].reading];
      if (sReadingIndex == 0 && sReadings[i].reading != 0) {
        readingToStructIndex[sReadings[i].reading] = numOfReadings; 
        sensorReadings.push(sReadings[i]);
        numOfReadings++;
      }
    }
  
    // Call this again for parent node (intended effect: send the values all the way up to the sink nodes)
    if (address(parentNode) != 0x0000000000000000000000000000000000000000) {
      parentNode.readSensorInput(sensorReadings);
    }
  }
  
  function getSensorReadings() public view returns(uint256[] memory) {
    uint256[] memory sensorReadingsUint = new uint256[](numOfReadings);
    
    for (uint i = 0; i < numOfReadings; i++) {
      sensorReadingsUint[i] = sensorReadings[i+1].reading;
    }
    
    return sensorReadingsUint;
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
