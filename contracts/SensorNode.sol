// SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "./DS.sol";
import "./IA.sol";
// import "./SomeLib.sol";

library SensorNode {

  // Events
  event LogString(string str);

  // DS.Node constructor
  function initNodeStruct(DS.Node storage daNode, uint _id, uint256 _addr, uint _energyLevel) public {
    daNode.nodeID = _id;
    daNode.nodeAddress = _addr;
    daNode.energyLevel = _energyLevel;
    daNode.networkLevel = 0; // invalid value for now

    // TODO relocate this to NetworkFormation?
    // Add a dummy 'null' beacon as the 1st element to make null-checking easy
    uint[] memory dummyAddrs = new uint[](1);
    dummyAddrs[0] = 0;
    daNode.beacons.push(DS.Beacon(false, 0, 0, dummyAddrs));
    
    // Add a dummy 'null' reading as the 1st element to make null-checking easy
    daNode.sensorReadings.push(DS.SensorReading(0, false));
  }
  
  // // test func for calling library function
  // function getMeFive(DS.Node storage daNode) public view returns(uint) {
  //   return SomeLib.getMeFive();
  // }
  
  // Get a node from the given DS.Node[] array and mapping with the given address
  function getNode(DS.Node[] storage _allNodes, mapping(uint => uint) storage _addrToNodeIndex, uint _nodeAddr) view public returns(DS.Node storage) {
    uint nIdx = _addrToNodeIndex[_nodeAddr];
    return _allNodes[nIdx];
  }
  
  ////////////////////////////////////////
  // Simulate receiving beacon from cluster head!
  ////////////////////////////////////////
  
  function addBeacon(DS.Node storage daNode, DS.Beacon memory _beacon) public {
    daNode.beacons.push(_beacon);
    daNode.numOfBeacons++;
  }
  
  function getBeacon(DS.Node storage daNode) public view returns(DS.Beacon memory) {
    if (daNode.beacons.length > 1) {
      return daNode.beacons[1];
    }
    return daNode.beacons[0];
  }
  
  // Get a beacon at the specified index.
  function getBeaconAt(DS.Node storage daNode, uint index) public view returns(DS.Beacon memory) {
    if (daNode.beacons.length > 1 && index < daNode.beacons.length - 1) {
      return daNode.beacons[index + 1];
    }
    return daNode.beacons[0];
  }
  
  function getBeacons(DS.Node storage daNode) public view returns(DS.Beacon[] memory) {
    return daNode.beacons;
  }
  
  ////////////////////////////////////////
  // Simulate receiving input from sensors!
  ////////////////////////////////////////

  /**
   * @notice Read sensor input.
   * @param _allNodes List of all DS.Node instances
   * @param _addrToNodeIndex Mapping from DS.Node addresses to their index in the array
   * @param daNode Node to read readings from 
   * @param _sReadings List of sensor readings to input 
   */
  function readSensorInput(
      DS.Node[] storage _allNodes, 
      mapping(uint => uint) storage _addrToNodeIndex, 
      DS.Node storage daNode, 
      DS.SensorReading[] memory _sReadings) public {
    
    // Add incoming sensor readings to this node's list of sensor readings
    for (uint i = 0; i < _sReadings.length; i++) {

      // Check if the sensor reading has already been added before adding it.
      // Ignore duplicates and null '0' readings
      bool isnotPresent = true;
      
      for (uint j = 0; j < daNode.sensorReadings.length; j++) {
        // If a match is found, ignore it
        if (_sReadings[i].reading == daNode.sensorReadings[j].reading) {
          isnotPresent = false;
        }
      }
      
      if (isnotPresent) {
        daNode.sensorReadings.push(_sReadings[i]);
        daNode.numOfReadings++;
      }
    }
  
    // Call this again for parent node (intended effect: send the values all the way up to the sink nodes)
    if (daNode.parentNode != 0) {
      DS.Node storage parentDsnode = getNode(_allNodes, _addrToNodeIndex, daNode.parentNode);
      readSensorInput(_allNodes, _addrToNodeIndex, parentDsnode, daNode.sensorReadings);
    }
  }
  
  function getSensorReadings(DS.Node storage daNode) public view returns(uint256[] memory) {
    uint256[] memory sensorReadingsUint = new uint256[](daNode.numOfReadings);
    
    for (uint i = 0; i < daNode.numOfReadings; i++) {
      sensorReadingsUint[i] = daNode.sensorReadings[i+1].reading;
    }
    
    return sensorReadingsUint;
  }

  ////////////////////////////////////////
  // Get backup cluster heads from beacons
  ////////////////////////////////////////
  
  function identifyBackups(DS.Node storage daNode) public {
    // TODO implement this setup (as an iterative function) in SensorNode!
    // IDEA: manually loop thru each array I guess - just use the length of the shortest array (since the size of the intersection cannot be larger than the shortest array)?

    
    // delete arrtemp1;
    // IA.inter(arrtemp2, daNode.withinRangeNodes, arrtemp1);
  
  }
    
  ////////////////////////////////////////
  // SETTER FUNCTIONS
  ////////////////////////////////////////
  
  function setEnergyLevel(DS.Node storage daNode, uint _eLevel) public {
    daNode.energyLevel = _eLevel;
  }
  
  function setNetworkLevel(DS.Node storage daNode, uint _nLevel) public {
    daNode.networkLevel = _nLevel;
  }
  
  function setAsClusterHead(DS.Node storage daNode) public {
    assert(daNode.isMemberNode == false);
    daNode.isClusterHead = true;
  }
  
  function setAsMemberNode(DS.Node storage daNode) public {
    assert(daNode.isClusterHead == false);
    daNode.isMemberNode = true;
  }
  
  function setParentNode(DS.Node storage daNode, uint256 _nodeAddr) public {
    daNode.parentNode = _nodeAddr;
  }
  
  function addJoinRequestNode(DS.Node storage daNode, uint256 _nodeAddr) public {
    daNode.joinRequestNodes.push(_nodeAddr);
    daNode.numOfJoinRequests++;
  }

  function addWithinRangeNode(DS.Node storage daNode, uint256 _addr) public {
    daNode.withinRangeNodes.push(_addr);
  }
    
  ////////////////////////////////////////
  // childNodes GETTER FUNCTIONS
  ////////////////////////////////////////
  
  function numOfChildNodes(DS.Node storage daNode) public view returns (uint) {
    return daNode.childNodes.length;
  }
  
  ////////////////////////////////////////
  // joinRequestNodes GETTER FUNCTIONS
  ////////////////////////////////////////
  
  function getJoinRequestNodes(DS.Node storage daNode) public view returns (uint256[] memory) {
    return daNode.joinRequestNodes;
  }
  
  ////////////////////////////////////////
  // withinRangeNodes GETTER FUNCTIONS
  ////////////////////////////////////////
  
  function getWithinRangeNodes(DS.Node storage daNode) public view returns (uint256[] memory) {
    return daNode.withinRangeNodes;
  }
  
  function numOfWithinRangeNodes(DS.Node storage daNode) public view returns (uint) {
    return daNode.withinRangeNodes.length;
  }
  
  ////////////////////////////////////////
  // Conversion functions
  ////////////////////////////////////////
  
  /**
   * @notice Convert an array of uint256 addresses into an array of their corresponding DS.Node instances. 
   * @param _allNodes List of all DS.Node instances
   * @param _addrToNodeIndex Mapping from DS.Node addresses to their index in the array
   * @param _nodeAddrs The array of uint256 addresses 
   * @return An array of DS.Node instances matching the given uint256 addresses
   */
  function nodeAddrsToNodes(DS.Node[] storage _allNodes, mapping(uint => uint) storage _addrToNodeIndex, uint256[] memory _nodeAddrs) public view returns(DS.Node[] memory) {
    DS.Node[] memory nodes = new DS.Node[](_nodeAddrs.length);
    for (uint i = 0; i < _nodeAddrs.length; i++) {
      nodes[i] = getNode(_allNodes, _addrToNodeIndex, _nodeAddrs[i]);
    }
    
    return nodes;
  }
  
}
