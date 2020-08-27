// SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "./DS.sol";
import "./IA.sol";
// import "./SomeLib.sol";

contract SensorNode {
  DS.Node daNode;

  // Events
  event LogString(string str);

  // SensorNode constructor
  constructor(uint _id, uint256 _addr, uint _energyLevel) public {
    daNode.nodeID = _id;
    daNode.nodeAddress = _addr;
    daNode.energyLevel = _energyLevel;
    daNode.networkLevel = 0; // invalid value for now

    // Add a dummy 'null' beacon as the 1st element to make null-checking easy
    uint[] memory dummyAddrs = new uint[](1);
    dummyAddrs[0] = 0;
    daNode.beacons.push(DS.Beacon(false, 0, 0, dummyAddrs));
    
    // Add a dummy 'null' reading as the 1st element to make null-checking easy
    daNode.sensorReadings.push(DS.SensorReading(0, false));
  }
  
  // // test func for calling library function
  // function getMeFive() public view returns(uint) {
  //   return SomeLib.getMeFive();
  // }
  
  ////////////////////////////////////////
  // Simulate receiving beacon from cluster head!
  ////////////////////////////////////////
  
  function addBeacon(DS.Beacon memory _beacon) public {
    daNode.beacons.push(_beacon);
    daNode.numOfBeacons++;
  }
  
  function getBeacon() public view returns(DS.Beacon memory) {
    if (daNode.beacons.length > 1) {
      return daNode.beacons[1];
    }
    return daNode.beacons[0];
  }
  
  // Get a beacon at the specified index.
  function getBeaconAt(uint index) public view returns(DS.Beacon memory) {
    if (daNode.beacons.length > 1 && index < daNode.beacons.length - 1) {
      return daNode.beacons[index + 1];
    }
    return daNode.beacons[0];
  }
  
  function getBeacons() public view returns(DS.Beacon[] memory) {
    return daNode.beacons;
  }
  
  ////////////////////////////////////////
  // Simulate receiving input from sensors!
  ////////////////////////////////////////
  function readSensorInput(DS.SensorReading[] memory _sReadings) public {
    
    // Add incoming sensor readings to this node's list of sensor readings
    for (uint i = 0; i < _sReadings.length; i++) {

      // Check if the sensor reading has already been added before adding it.
      // Ignore duplicates and null '0' readings
      uint sReadingIndex = daNode.readingToStructIndex[_sReadings[i].reading];
      if (sReadingIndex == 0 && _sReadings[i].reading != 0) {
        daNode.readingToStructIndex[_sReadings[i].reading] = daNode.numOfReadings; 
        daNode.sensorReadings.push(_sReadings[i]);
        daNode.numOfReadings++;
      }
    }
  
    // COMMENTED OUT FOR NOW
    // // Call this again for parent node (intended effect: send the values all the way up to the sink nodes)
    // if (address(daNode.parentNode) != 0x0000000000000000000000000000000000000000) {
    //   daNode.parentNode.readSensorInput(daNode.sensorReadings);
    // }
  }
  
  function getSensorReadings() public view returns(uint256[] memory) {
    uint256[] memory sensorReadingsUint = new uint256[](daNode.numOfReadings);
    
    for (uint i = 0; i < daNode.numOfReadings; i++) {
      sensorReadingsUint[i] = daNode.sensorReadings[i+1].reading;
    }
    
    return sensorReadingsUint;
  }

  ////////////////////////////////////////
  // Get backup cluster heads from beacons
  ////////////////////////////////////////
  // function identifyBackups() public {
  //   // TODO implement this setup (as an iterative function) in SensorNode!
  //   delete arrtemp1;
  //   IA.inter(arrtemp2, withinRangeNodes, arrtemp1);
  // 
  // }
    
  ////////////////////////////////////////
  // SETTER FUNCTIONS
  ////////////////////////////////////////
  
  function setEnergyLevel(uint _eLevel) public {
    daNode.energyLevel = _eLevel;
  }
  
  function setNetworkLevel(uint _nLevel) public {
    daNode.networkLevel = _nLevel;
  }
  
  function setAsClusterHead() public {
    assert(daNode.isMemberNode == false);
    daNode.isClusterHead = true;
  }
  
  function setAsMemberNode() public {
    assert(daNode.isClusterHead == false);
    daNode.isMemberNode = true;
  }
  
  function setParentNode(uint256 _nodeAddr) public {
    daNode.parentNode = _nodeAddr;
  }
  
  function addJoinRequestNode(uint256 _nodeAddr) public {
    daNode.joinRequestNodes.push(_nodeAddr);
    daNode.numOfJoinRequests++;
  }

  function addWithinRangeNode(uint256 _addr) public {
    daNode.withinRangeNodes.push(_addr);
  }
    
  ////////////////////////////////////////
  // childNodes GETTER FUNCTIONS
  ////////////////////////////////////////
  
  function numOfChildNodes() public view returns (uint) {
    return daNode.childNodes.length;
  }
  
  ////////////////////////////////////////
  // joinRequestNodes GETTER FUNCTIONS
  ////////////////////////////////////////
  
  function getJoinRequestNodes() public view returns (uint256[] memory) {
    return daNode.joinRequestNodes;
  }
  
  ////////////////////////////////////////
  // withinRangeNodes GETTER FUNCTIONS
  ////////////////////////////////////////
  
  function getWithinRangeNodes() public view returns (uint256[] memory) {
    return daNode.withinRangeNodes;
  }
  
  function numOfWithinRangeNodes() public view returns (uint) {
    return daNode.withinRangeNodes.length;
  }
  
  // TODO:
  // make functions to add/get/remove elements in the arrays
}
