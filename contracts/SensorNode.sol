// SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "./DS.sol";
import "./IA.sol";
import "./QuickSort.sol";
// import "./SomeLib.sol";

library SensorNode {

  // Events
  event LogString(string str);

  /**
   * @notice Initialise the given node struct with the given values.
   * @param _daNode The node to modify
   * @param _addr Node address
   * @param _energyLevel Node energy level
   */
  function initNodeStruct(DS.Node storage _daNode, uint256 _addr, uint _energyLevel) public {
    _daNode.nodeAddress = _addr;
    _daNode.energyLevel = _energyLevel;
    _daNode.networkLevel = 0; // invalid value for now

    // TODO relocate this to NetworkFormation?
    // Add a dummy 'null' beacon as the 1st element to make null-checking easy
    uint[] memory dummyAddrs = new uint[](1);
    dummyAddrs[0] = 0;
    _daNode.beacons.push(DS.Beacon(false, 0, 0, dummyAddrs));
    
    // Add a dummy 'null' reading as the 1st element to make null-checking easy
    _daNode.sensorReadings.push(DS.SensorReading(0, false));
    
    // Mark the node as active
    _daNode.isActive = true;
  }
  
  // // test func for calling library function
  // function getMeFive(DS.Node storage _daNode) public view returns(uint) {
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
   * @param _daNode The node to modify
   */
  function addBeacon(DS.Node storage _daNode, DS.Beacon memory _beacon) public {
    _daNode.beacons.push(_beacon);
    _daNode.numOfBeacons++;
  }
  
  /**
   * @notice Get the 1st beacon sent to this node.
   * @param _daNode The node to get the beacon from
   * @return The 1st beacon struct sent to the given node
   */
  function getBeacon(DS.Node storage _daNode) public view returns(DS.Beacon memory) {
    if (_daNode.beacons.length > 1) {
      return _daNode.beacons[1];
    }
    return _daNode.beacons[0];
  }
  
  /**
   * @notice Get the n'th beacon sent to this node.
   * @param _daNode The node to get the beacons from
   * @param index Array index to get the beacon from
   * @return The beacon struct sent to the given node
   */
  function getBeaconAt(DS.Node storage _daNode, uint index) public view returns(DS.Beacon memory) {
    if (_daNode.beacons.length > 1 && index < _daNode.beacons.length - 1) {
      return _daNode.beacons[index + 1];
    }
    return _daNode.beacons[0];
  }
  
  /**
   * @notice Get all beacons from this node.
   * @param _daNode The node to modify
   * @return List of all beacons sent to the given node
   */
  function getBeacons(DS.Node storage _daNode) public view returns(DS.Beacon[] memory) {
    return _daNode.beacons;
  }
  
  ////////////////////////////////////////
  // Redundancy fuinctions
  ////////////////////////////////////////

  function setBackupAsClusterHead(
      DS.Node storage _daNode,
      DS.Node[] storage _allNodes, 
      mapping(uint => uint) storage _addrToNodeIndex) public {
    // find backup with highest energy level
    
    // Convert list of backup node addresses into their corresponding nodes
    DS.Node[] memory backupCHeadNodes = nodeAddrsToNodes(_allNodes, _addrToNodeIndex, _daNode.backupCHeads);
    
    // Sort the backup cluster head candidates by their current energy level in descending order
    // NOTE: doesn't work - 1st element is null (?)
    //backupCHeadNodes = QuickSort.sort(backupCHeadNodes);

    // TODO: find out way to re-instate the original cluster head if it is active again (?)
    // Set the backup candidate with highest energy level as the new cluster head
    if (backupCHeadNodes[0].nodeAddress != 0) {
      DS.Node storage backupCHead = getNode(_allNodes, _addrToNodeIndex, backupCHeadNodes[0].nodeAddress);
      setAsClusterHead(backupCHead);
      setParentNode(_daNode, backupCHead.nodeAddress);
    }
  }

  ////////////////////////////////////////
  // Simulate receiving input from sensors!
  ////////////////////////////////////////

  /**
   * @notice Read sensor input.
   * @param _daNode Node to read readings from 
   * @param _allNodes List of all DS.Node instances
   * @param _addrToNodeIndex Mapping from DS.Node addresses to their index in the array
   * @param _sReadings List of sensor readings to input 
   */
  function readSensorInput(
      DS.Node storage _daNode, 
      DS.Node[] storage _allNodes, 
      mapping(uint => uint) storage _addrToNodeIndex, 
      DS.SensorReading[] memory _sReadings) public {
    
    // Add incoming sensor readings to this node's list of sensor readings
    for (uint i = 0; i < _sReadings.length; i++) {

      // Check if the sensor reading has already been added before adding it.
      // Ignore duplicates and null '0' readings
      bool isnotPresent = true;
      
      for (uint j = 0; j < _daNode.sensorReadings.length; j++) {
        // If a match is found, ignore it
        if (_sReadings[i].reading == _daNode.sensorReadings[j].reading) {
          isnotPresent = false;
        }
      }
      
      if (isnotPresent) {
        _daNode.sensorReadings.push(_sReadings[i]);
        _daNode.numOfReadings++;
      }
    }
  
    // Call this again for parent node (intended effect: send the values all the way up to the sink nodes)
    if (_daNode.links.parentNode != 0) {
      DS.Node storage parentDsnode = getNode(_allNodes, _addrToNodeIndex, _daNode.links.parentNode);
      
      // Elect backup cluster head node if current cluster head is unavailable
      if (!parentDsnode.isActive) {
        setBackupAsClusterHead(_daNode, _allNodes, _addrToNodeIndex);
        parentDsnode = getNode(_allNodes, _addrToNodeIndex, _daNode.links.parentNode);
      }
      
      readSensorInput(parentDsnode, _allNodes, _addrToNodeIndex, _daNode.sensorReadings);
    }
  }
  
  /**
   * @notice Make the given cluster head node send a response to sensor input.
   * @param _daNode Node to read readings from 
   * @param _allNodes List of all DS.Node instances
   * @param _addrToNodeIndex Mapping from DS.Node addresses to their index in the array
   */
  function respondToSensorInput(
      DS.Node storage _daNode, 
      DS.Node[] storage _allNodes, 
      mapping(uint => uint) storage _addrToNodeIndex,
      bool conditionsAreMatching) public {

    // Suppose we want to check if sensor reading > 37000 (= 37 degrees).
    // TODO make this more flexible
    for (uint i = 1; i < _daNode.sensorReadings.length; i++) {
      if (_daNode.sensorReadings[i].reading > 37000 || conditionsAreMatching) {
        
        // If this node is a controller, go thru each of its children nodes
        // and call this function on each of them      
        if (_daNode.ev.nodeRole == DS.NodeRole.Controller) {
          for (uint j = 0; j < _daNode.links.childNodes.length; j++) {
            DS.Node storage childNode = getNode(_allNodes, _addrToNodeIndex, _daNode.links.childNodes[j]);
            respondToSensorInput(childNode, _allNodes, _addrToNodeIndex, true);
          }
        }
      }
    }
    
    // Otherwise, if this node is an actuator, simulate triggering the device
    if (conditionsAreMatching && _daNode.ev.nodeRole == DS.NodeRole.Actuator) {
      _daNode.ev.isTriggeringExternalService = true;
    }
    
  }
  
  /**
   * @notice Get all sensor readings sent to this node.
   * @param _daNode The node to get the sensor readings from
   * @return The sensor readings sent to the given node
   */
  function getSensorReadings(DS.Node storage _daNode) public view returns(uint256[] memory) {
    uint256[] memory sensorReadingsUint = new uint256[](_daNode.numOfReadings);
    
    for (uint i = 0; i < _daNode.numOfReadings; i++) {
      sensorReadingsUint[i] = _daNode.sensorReadings[i+1].reading;
    }
    
    return sensorReadingsUint;
  }

  ////////////////////////////////////////
  // Get backup cluster heads from beacons
  ////////////////////////////////////////
  
  /**
   * @notice Identify the nodes which can serve as a backup in case the current cluster head fails by going through the list of links.withinRangeNodes on all received beacons and then saving the results to the list of backup cluster head addresses for that node.
   * @param _daNode The node to identify backup cluster heads for
   */
  function identifyBackupClusterHeads(DS.Node storage _daNode) public {
    uint256[] memory result = _daNode.links.withinRangeNodes;
    
    // Need to have at least 2 beacons (1st one is the 'null' beacon)
    if (_daNode.beacons.length > 1) {
      for (uint i = 1; i < _daNode.beacons.length; i++) {
        result = IA.inter(result, _daNode.beacons[i].withinRangeNodes);
      }
      
      _daNode.backupCHeads = result;
    }
  }
    
  ////////////////////////////////////////
  // SETTER FUNCTIONS
  ////////////////////////////////////////
  
  /**
   * @notice Set the energy level of this node.
   * @param _daNode The node to modify
   * @param _eLevel New energy level
   */
  function setEnergyLevel(DS.Node storage _daNode, uint _eLevel) public {
    _daNode.energyLevel = _eLevel;
  }
  
  /**
   * @notice Set the network level of this node.
   * @param _daNode The node to modify
   * @param _nLevel New network level
   */
  function setNetworkLevel(DS.Node storage _daNode, uint _nLevel) public {
    _daNode.networkLevel = _nLevel;
  }
    
  /**
   * @notice Set the given node as a cluster head.
   * @param _daNode The node to set
   */
  function setAsClusterHead(DS.Node storage _daNode) public {
    //assert(_daNode.isMemberNode == false);
    // _daNode.isClusterHead = true;
    // _daNode.isMemberNode = false;
    _daNode.nodeType = DS.NodeType.ClusterHead;
  }
  
  /**
   * @notice Set the given node as a member node.
   * @param _daNode The node to set
   */
  function setAsMemberNode(DS.Node storage _daNode) public {
    //assert(_daNode.isClusterHead == false);
    // _daNode.isClusterHead = false;
    // _daNode.isMemberNode = true;
    _daNode.nodeType = DS.NodeType.MemberNode;
  }
  
  /**
   * @notice Set the parent node (cluster head) for this node.
   * @param _daNode The node to modify
   * @param _nodeAddr The address of the cluster head that connects to this node
   */
  function setParentNode(DS.Node storage _daNode, uint256 _nodeAddr) public {
    _daNode.links.parentNode = _nodeAddr;
  }
  
  /**
   * @notice Add the address of a child node to this node.
   * @param _daNode The node to modify
   * @param _nodeAddr The address of the child node
   */
  function addChildNode(DS.Node storage _daNode, uint256 _nodeAddr) public {
    _daNode.links.childNodes.push(_nodeAddr);
  }

  /**
   * @notice Add the address of a join request node to this node.
   * @param _daNode The node to modify
   * @param _nodeAddr The address of the node that sent a join request to this node
   */
  function addJoinRequestNode(DS.Node storage _daNode, uint256 _nodeAddr) public {
    _daNode.links.joinRequestNodes.push(_nodeAddr);
    _daNode.links.numOfJoinRequests++;
  }

  /**
   * @notice Add the address of a node within range to this node.
   * @param _daNode The node to modify
   * @param _addr The address of the node within the transmission range of this node
   */
  function addWithinRangeNode(DS.Node storage _daNode, uint256 _addr) public {
    _daNode.links.withinRangeNodes.push(_addr);
  }
    
  /**
   * @notice Deactivate the given node.
   * @param _daNode The node to deactivate
   */
  function deactivateNode(DS.Node storage _daNode) public {
    require(_daNode.isActive == true);
    _daNode.isActive = false;
  }
    
  /**
   * @notice Activate the given node.
   * @param _daNode The node to activate
   */
  function activateNode(DS.Node storage _daNode) public {
    require(_daNode.isActive == false);
    _daNode.isActive = true;
  }
    
  /**
   * @notice Set the given node's role as a sensor node.
   * @param _daNode The node to set
   */
  function setAsSensorRole(DS.Node storage _daNode) public {
    _daNode.ev.nodeRole = DS.NodeRole.Sensor;
  }
  
  /**
   * @notice Set the given node's role as a controller.
   * @param _daNode The node to set
   */
  function setAsControllerRole(DS.Node storage _daNode) public {
    _daNode.ev.nodeRole = DS.NodeRole.Controller;
  }
  
  /**
   * @notice Set the given node's role as an actuator.
   * @param _daNode The node to set
   */
  function setAsActuatorRole(DS.Node storage _daNode, string memory _triggerMessage) public {
    _daNode.ev.nodeRole = DS.NodeRole.Actuator;
    _daNode.ev.triggerMessage = _triggerMessage;
  }
  
  ////////////////////////////////////////
  // links.childNodes GETTER FUNCTIONS
  ////////////////////////////////////////
  
  /**
   * @notice Get the number of child nodes of the given node.
   * @param _daNode The node to check
   * @return The number of child nodes
   */
  function numOfChildNodes(DS.Node storage _daNode) public view returns (uint) {
    return _daNode.links.childNodes.length;
  }
  
  ////////////////////////////////////////
  // links.joinRequestNodes GETTER FUNCTIONS
  ////////////////////////////////////////
  
   /**
    * @notice Get the addresses of all nodes that sent join requests to this node.
    * @param _daNode The node to get the addresses from
    * @return The addresses of the join request nodes
    */
  function getJoinRequestNodes(DS.Node storage _daNode) public view returns (uint256[] memory) {
    return _daNode.links.joinRequestNodes;
  }
  
  ////////////////////////////////////////
  // links.withinRangeNodes GETTER FUNCTIONS
  ////////////////////////////////////////
  
  /**
   * @notice Get the addresses of all nodes within range to this node.
   * @param _daNode The node to get the addresses from
   * @return The addresses of the nodes within range
   */
  function getWithinRangeNodes(DS.Node storage _daNode) public view returns (uint256[] memory) {
    return _daNode.links.withinRangeNodes;
  }
  
  /**
   * @notice Get the number of nodes within range to this node.
   * @param _daNode The node to check
   * @return The number of nodes within range
   */
  function numOfWithinRangeNodes(DS.Node storage _daNode) public view returns (uint) {
    return _daNode.links.withinRangeNodes.length;
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
