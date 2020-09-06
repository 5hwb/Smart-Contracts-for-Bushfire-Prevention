// SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "./DS.sol";
import "./IA.sol";
// import "./SomeLib.sol";

library SensorNode {

  // Events
  event LogString(string str);

  /**
   * @notice Initialise the given node struct with the given values.
   * @param daNode The node to modify
   * @param _id Node ID
   * @param _addr Node address
   * @param _energyLevel Node energy level
   */
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
    
    // Mark the node as active
    daNode.isActive = true;
  }
  
  // // test func for calling library function
  // function getMeFive(DS.Node storage daNode) public view returns(uint) {
  //   return SomeLib.getMeFive();
  // }
  
  /**
   * @notice Get a node from the given DS.Node[] array and mapping with the given address.
   * @param _allNodes Array of node structs
   * @param _addrToNodeIndex Mapping from node address to array index
   * @param _nodeAddr The address of the node to get
   * @return The node with the given node address
   */
  function getNode(DS.Node[] storage _allNodes, mapping(uint => uint) storage _addrToNodeIndex, uint _nodeAddr) view public returns(DS.Node storage) {
    uint nIdx = _addrToNodeIndex[_nodeAddr];
    return _allNodes[nIdx];
  }
  
  ////////////////////////////////////////
  // Simulate receiving beacon from cluster head!
  ////////////////////////////////////////
  
  /**
   * @notice Add a beacon to the given node.
   * @param daNode The node to modify
   */
  function addBeacon(DS.Node storage daNode, DS.Beacon memory _beacon) public {
    daNode.beacons.push(_beacon);
    daNode.numOfBeacons++;
  }
  
  /**
   * @notice Get the 1st beacon sent to this node.
   * @param daNode The node to get the beacon from
   * @return The 1st beacon struct sent to the given node
   */
  function getBeacon(DS.Node storage daNode) public view returns(DS.Beacon memory) {
    if (daNode.beacons.length > 1) {
      return daNode.beacons[1];
    }
    return daNode.beacons[0];
  }
  
  /**
   * @notice Get the n'th beacon sent to this node.
   * @param daNode The node to get the beacons from
   * @param index Array index to get the beacon from
   * @return The beacon struct sent to the given node
   */
  function getBeaconAt(DS.Node storage daNode, uint index) public view returns(DS.Beacon memory) {
    if (daNode.beacons.length > 1 && index < daNode.beacons.length - 1) {
      return daNode.beacons[index + 1];
    }
    return daNode.beacons[0];
  }
  
  /**
   * @notice Get all beacons from this node.
   * @param daNode The node to modify
   * @return List of all beacons sent to the given node
   */
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
  
  /**
   * @notice Get all sensor readings sent to this node.
   * @param daNode The node to get the sensor readings from
   * @return The sensor readings sent to the given node
   */
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
  
  /**
   * @notice Identify the nodes which can serve as a backup in case the current cluster head fails by going through the list of withinRangeNodes on all received beacons and then saving the results to the list of backup cluster head addresses for that node.
   * @param daNode The node to identify backup cluster heads for
   */
  function identifyBackupClusterHeads(DS.Node storage daNode) public {
    uint256[] memory result = daNode.withinRangeNodes;
    
    // Need to have at least 2 beacons (1st one is the 'null' beacon)
    if (daNode.beacons.length > 1) {
      for (uint i = 1; i < daNode.beacons.length; i++) {
        result = IA.inter(result, daNode.beacons[i].withinRangeNodes);
      }
      
      daNode.backupCHeads = result;
    }
  }
    
  ////////////////////////////////////////
  // SETTER FUNCTIONS
  ////////////////////////////////////////
  
  /**
   * @notice Set the energy level of this node.
   * @param daNode The node to modify
   * @param _eLevel New energy level
   */
  function setEnergyLevel(DS.Node storage daNode, uint _eLevel) public {
    daNode.energyLevel = _eLevel;
  }
  
  /**
   * @notice Set the network level of this node.
   * @param daNode The node to modify
   * @param _nLevel New network level
   */
  function setNetworkLevel(DS.Node storage daNode, uint _nLevel) public {
    daNode.networkLevel = _nLevel;
  }
    
  /**
   * @notice Set the given node as a cluster head.
   * @param daNode The node to set
   */
  function setAsClusterHead(DS.Node storage daNode) public {
    //assert(daNode.isMemberNode == false);
    daNode.isClusterHead = true;
    daNode.isMemberNode = false;
  }
  
  /**
   * @notice Set the given node as a member node.
   * @param daNode The node to set
   */
  function setAsMemberNode(DS.Node storage daNode) public {
    //assert(daNode.isClusterHead == false);
    daNode.isClusterHead = false;
    daNode.isMemberNode = true;
  }
  
  /**
   * @notice Set the parent node (cluster head) for this node.
   * @param daNode The node to modify
   * @param _nodeAddr The address of the cluster head that connects to this node
   */
  function setParentNode(DS.Node storage daNode, uint256 _nodeAddr) public {
    daNode.parentNode = _nodeAddr;
  }
  
  /**
   * @notice Add the address of a join request node to this node.
   * @param daNode The node to modify
   * @param _nodeAddr The address of the node that sent a join request to this node
   */
  function addJoinRequestNode(DS.Node storage daNode, uint256 _nodeAddr) public {
    daNode.joinRequestNodes.push(_nodeAddr);
    daNode.numOfJoinRequests++;
  }

  /**
   * @notice Add the address of a node within range to this node.
   * @param daNode The node to modify
   * @param _addr The address of the node within the transmission range of this node
   */
  function addWithinRangeNode(DS.Node storage daNode, uint256 _addr) public {
    daNode.withinRangeNodes.push(_addr);
  }
    
  /**
   * @notice Deactivate the given node.
   * @param daNode The node to deactivate
   */
  function deactivateNode(DS.Node storage daNode) public {
    require(daNode.isActive == true);
    daNode.isActive = false;
  }
    
  /**
   * @notice Activate the given node.
   * @param daNode The node to activate
   */
  function activateNode(DS.Node storage daNode) public {
    require(daNode.isActive == false);
    daNode.isActive = true;
  }
    
  ////////////////////////////////////////
  // childNodes GETTER FUNCTIONS
  ////////////////////////////////////////
  
  /**
   * @notice Get the number of child nodes of the given node.
   * @param daNode The node to check
   * @return The number of child nodes
   */
  function numOfChildNodes(DS.Node storage daNode) public view returns (uint) {
    return daNode.childNodes.length;
  }
  
  ////////////////////////////////////////
  // joinRequestNodes GETTER FUNCTIONS
  ////////////////////////////////////////
  
   /**
    * @notice Get the addresses of all nodes that sent join requests to this node.
    * @param daNode The node to get the addresses from
    * @return The addresses of the join request nodes
    */
  function getJoinRequestNodes(DS.Node storage daNode) public view returns (uint256[] memory) {
    return daNode.joinRequestNodes;
  }
  
  ////////////////////////////////////////
  // withinRangeNodes GETTER FUNCTIONS
  ////////////////////////////////////////
  
  /**
   * @notice Get the addresses of all nodes within range to this node.
   * @param daNode The node to get the addresses from
   * @return The addresses of the nodes within range
   */
  function getWithinRangeNodes(DS.Node storage daNode) public view returns (uint256[] memory) {
    return daNode.withinRangeNodes;
  }
  
  /**
   * @notice Get the number of nodes within range to this node.
   * @param daNode The node to check
   * @return The number of nodes within range
   */
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
