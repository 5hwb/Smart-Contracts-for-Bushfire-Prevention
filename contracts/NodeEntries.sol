// SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "./DS.sol";
import "./QuickSort.sol";
import "./NodeEntryLib.sol";
import "./NodeRoleEntries.sol";

// A smart contract that contains all node entries in the wireless sensor network (WSN).
contract NodeEntries {
  
  /** The number of cluster heads in the WSN */
  uint numOfClusterHeads;
  
  /** Array of all nodes in the network */
  DS.Node[] public allNodes;
  
  /** Mapping from node addresses to the corresponding array index in allNodes */
  mapping (uint => uint) addrToNodeIndex;

  /** Number of nodes in this network */
  uint public numOfNodes;
  /** How many levels the network is consisted of */
  uint public numOfLevels;
  
  /** Smart contract for the node role entries */
  NodeRoleEntries nodeRoleEntries;
  
  // Events
  event AddedNode(uint256 addr, uint energyLevel, uint networkLevel, DS.NodeType nodeType);
  event SomethingHappened(uint i, uint cHeadAddr, uint nodeAddr, uint numOfWithinRangeNodes, string msg);

  /**
   * @notice Set the deployed NodeRoleEntries contract instance to use. 
   * @param _nre The NodeRoleEntries instance to set
   */
  function setNodeRoleEntries(NodeRoleEntries _nre) public {
    nodeRoleEntries = _nre;
  }
  
  /**
   * @notice Get array of all DS.Node instances. Note: this is for reading only!
   * @return The array of DS.Node structs
   */
  function getAllNodes() view public returns(DS.Node[] memory) {
    return allNodes;
  }
  
  /**
   * @notice Get array of addresses of all DS.Node instances.
   * @return The array of node addresses
   */
  function getAllNodeAddresses() view public returns(uint[] memory) {
    uint[] memory nodeAddresses = new uint[](numOfNodes);
    for (uint i = 0; i < numOfNodes; i++) {
      nodeAddresses[i] = allNodes[i].nodeAddress;
    }
    return nodeAddresses;
  }
  
  /**
   * @notice Add a node to the list of all node entries.
   * @param _addr The node address
   * @param _energyLevel The node energy level
   * @param _withinRangeNodes The array of addresses of nodes within range of this node
   */
  function addNode(uint _addr, uint _energyLevel, uint[] memory _withinRangeNodes) public {
    // Push a new DS.Node instance onto the array of nodes
    DS.Node storage node = allNodes.push();

    // Initialise the empty node's values
    NodeEntryLib.initNodeStruct(node, _addr, _energyLevel);
    for (uint i = 0; i < _withinRangeNodes.length; i++) {
      NodeEntryLib.addWithinRangeNode(node, _withinRangeNodes[i]);
    }
        
    // Add mapping of address to node array index 
    addrToNodeIndex[_addr] = numOfNodes;
    numOfNodes++;

    emit AddedNode(_addr, _energyLevel, node.networkLevel, node.nodeType);
    
    // Call NodeRoleEntries - add an entry as well
    nodeRoleEntries.addNode(_addr);
  }
  
  /**
   * @notice Get the index of the node with the given address.
   * @param _nodeAddr Address of node to get
   * @return The array index of the node entry 
   */
  function getNodeIndex(uint _nodeAddr) view public returns(uint) {
    return addrToNodeIndex[_nodeAddr];
  }
  
  /**
   * @notice Get the node with the given address.
   * @param _nodeAddr Address of node to get
   * @return The node entry 
   */
  function getNodeEntry(uint _nodeAddr) view public returns(DS.Node memory) {
    uint nIdx = addrToNodeIndex[_nodeAddr];
    return allNodes[nIdx];
  }
  
  /**
   * @notice Get the node at the given array index.
   * @param _index Array index of node to get
   * @return The node entry 
   */
  function getNodeAt(uint _index) view public returns(DS.Node memory) {
    return allNodes[_index];
  }
  
  /**
   * @notice Get node information. Use this for external apps (as directly using
             functions returning structs in Web3 doesn't work).
   * @param _nodeAddr Address of node to get info from
   * @return A tuple containing: the node address, energy level, network level,
             node type, node role, active flag, trigger flag, trigger message
             and sensor readings 
   */
  function getNodeInfo(uint _nodeAddr) public view returns (
    uint256,
    uint, uint,
    DS.NodeType, DS.NodeRole,
    bool, bool, 
    string memory, uint256[] memory
    ) {
    uint nIdx = addrToNodeIndex[_nodeAddr];
    DS.NodeRoleEntry memory nodeRoleEntry = nodeRoleEntries.getNREntry(allNodes[nIdx].nodeAddress);
    
    return (allNodes[nIdx].nodeAddress, // 0
        allNodes[nIdx].energyLevel, allNodes[nIdx].networkLevel, // 1, 2
        allNodes[nIdx].nodeType, nodeRoleEntry.nodeRole, // 3, 4
        allNodes[nIdx].isActive, nodeRoleEntry.isTriggeringExternalService, // 5, 6
        nodeRoleEntry.triggerMessage, NodeEntryLib.getSensorReadings(allNodes[nIdx]) // 7, 8
        );
  }
  
  /**
   * @notice Get a node's beacon data.
   * @param _nodeAddr Address of node to get info from
   * @return A tuple containing: the beacon flag, next network level,
             address of node that sent this beacon, and 
             the number of beacons this node has received
   */
  function getNodeBeaconData(uint _nodeAddr) public view returns (
    bool, uint, uint256, uint) {      
    DS.Node storage node = NodeEntryLib.getNode(allNodes, addrToNodeIndex, _nodeAddr);
    DS.Beacon memory beacon = NodeEntryLib.getBeacon(node);
    return (beacon.isSent, beacon.nextNetLevel, beacon.senderNodeAddr, node.numOfBeacons);
  }

  /**
   * @notice Send beacon to prospective child nodes.
   * @param _cHeadAddr Address of cluster head to send the beacons from
   */
  function sendBeacon(uint _cHeadAddr) public {
    uint chIndex = getNodeIndex(_cHeadAddr);
    require(allNodes[chIndex].nodeType == DS.NodeType.ClusterHead, "Given node is not cluster head");

    // Get network level of this cluster head to calculate next level
    uint nextNetLevel = allNodes[chIndex].networkLevel;
    nextNetLevel++;
    
    // Go thru all nodes within range of the cluster head
    for (uint i = 0; i < NodeEntryLib.numOfWithinRangeNodes(allNodes[chIndex]); i++) {
      DS.Node storage currNode = NodeEntryLib.getNode(allNodes, addrToNodeIndex, allNodes[chIndex].links.withinRangeNodes[i]);
      
      // Ignore this node if it's a cluster head or if the network level is 
      // already set between 1 and the current cluster head's network level 
      if (currNode.nodeType == DS.NodeType.ClusterHead || (currNode.networkLevel > 0
          && currNode.networkLevel <= allNodes[chIndex].networkLevel)) {
        emit SomethingHappened(i, allNodes[chIndex].nodeAddress, currNode.nodeAddress, NodeEntryLib.numOfWithinRangeNodes(allNodes[chIndex]), "Node was ignored");
        continue;
      }

      // Send the beacon!
      emit SomethingHappened(i, allNodes[chIndex].nodeAddress, currNode.nodeAddress, NodeEntryLib.numOfWithinRangeNodes(allNodes[chIndex]), "Gonna set...");
      NodeEntryLib.setNetworkLevel(currNode, nextNetLevel);
      DS.Beacon memory beacon = DS.Beacon(true, nextNetLevel, allNodes[chIndex].nodeAddress, NodeEntryLib.getWithinRangeNodes(allNodes[chIndex]));
      NodeEntryLib.addBeacon(currNode, beacon);
    }
  }
  
  /**
   * @notice Send a join request to the given cluster head.
   * @param _sensorAddr Address of node entry to send the join requests from
   * @param _cHeadAddr Address of cluster head to send the join requests to
   */
  function sendJoinRequest(uint _sensorAddr, uint _cHeadAddr) public {
    uint nodeIndex = getNodeIndex(_sensorAddr);
    DS.Node storage cHeadNode = NodeEntryLib.getNode(allNodes, addrToNodeIndex, _cHeadAddr);
    
    // Add this node to cluster head's list of nodes that sent join requests
    assert(cHeadNode.nodeAddress != 0); // make sure the cluster head node exists
    NodeEntryLib.addJoinRequestNode(cHeadNode, allNodes[nodeIndex].nodeAddress);
  }
  
  event SentJoinRequest(uint256 _addr, uint _i);
  
  /**
   * @notice Go thru all nodes to see if they have received a beacon from
             a cluster head and need to send a join request back.
   */
  function sendJoinRequests() public {
    for (uint i = 0; i < numOfNodes; i++) {
      emit SentJoinRequest(allNodes[i].nodeAddress, i);
      // Send join request to cluster head iff a beacon has been received from that node
      require(allNodes[i].beacons.length > 0, "NO BEACONS!??");
      if (NodeEntryLib.getBeacon(allNodes[i]).isSent) {
        sendJoinRequest(allNodes[i].nodeAddress, NodeEntryLib.getBeacon(allNodes[i]).senderNodeAddr);
      }
    }
  }
  
  /**
   * @notice Identify the backup cluster heads for each node.
   */
  function identifyBackupClusterHeads() public {
    for (uint i = 0; i < numOfNodes; i++) {
      NodeEntryLib.identifyBackupClusterHeads(allNodes[i]);
    }
  }
  
  /**
   * @notice Register the given node as a cluster head.
   * @param _parentAddr Address of parent node of the would-be cluster head
   * @param _nodeAddr Address of node to set as cluster head
   */
  function registerAsClusterHead(uint _parentAddr, uint _nodeAddr) public {
    uint nodeIndex = getNodeIndex(_nodeAddr);
    uint parentIndex = getNodeIndex(_parentAddr);
    assert(allNodes[nodeIndex].nodeType == DS.NodeType.Unassigned);
    
    // By default, cluster heads are also Controllers,
    // hence they are assigned to the Controller role.
    NodeEntryLib.setAsClusterHead(allNodes[nodeIndex]);
    nodeRoleEntries.assignAsController(allNodes[nodeIndex].nodeAddress);
    
    // Set the parent node (only if valid address!) and add this node as the child node of the parent
    if (_parentAddr != 0) {
      NodeEntryLib.setParentNode(allNodes[nodeIndex], allNodes[parentIndex].nodeAddress);
      NodeEntryLib.addChildNode(allNodes[parentIndex], allNodes[nodeIndex].nodeAddress);
    }
  }
  
  /**
   * @notice Register the given node as a member node of the given cluster head.
   * @param _parentAddr Address of parent node of the would-be member node
   * @param _nodeAddr Address of node to set as member node
   */
  function registerAsMemberNode(uint _parentAddr, uint _nodeAddr) public {
    uint nodeIndex = getNodeIndex(_nodeAddr);
    uint parentIndex = getNodeIndex(_parentAddr);
    assert(allNodes[nodeIndex].nodeType == DS.NodeType.Unassigned);

    NodeEntryLib.setAsMemberNode(allNodes[nodeIndex]);

    // Set the parent node (only if valid address!) and add this node as the child node of the parent
    if (_parentAddr != 0) {
      NodeEntryLib.setParentNode(allNodes[nodeIndex], allNodes[parentIndex].nodeAddress);
      NodeEntryLib.addChildNode(allNodes[parentIndex], allNodes[nodeIndex].nodeAddress);
    }
  }
  
  /**
   * @notice Get a sorted array of node entries.
   * @return The sorted nodes
   */
  function getSortedNodes() public returns(DS.Node[] memory) {
    return QuickSort.sort(allNodes);
  }
  
  /**
   * @notice Elect the next cluster heads for the next layer using the GCA algorithm
             as described in Lee et al. (2011) with the given probability.
   * @param _currCHeadAddr Address of cluster head to elect child nodes
   * @param _probability The probability of a child node becoming a cluster head,
            indicated as a number between 0 (0%) and 100 (100%)
   */
  function electClusterHeads(uint _currCHeadAddr, uint _probability) public {
  
    // Get the node entry with the given address
    DS.Node storage currClusterHead = NodeEntryLib.getNode(allNodes, addrToNodeIndex, _currCHeadAddr);
    
    // Get the list of addresses of nodes that sent join requests
    // (if its empty, exit the function)
    uint256[] memory nodesWithJoinRequestAddrs = NodeEntryLib.getJoinRequestNodes(currClusterHead);
    if (nodesWithJoinRequestAddrs.length == 0) {
      return;
    }
    
    // Convert list of addresses into their corresponding nodes
    DS.Node[] memory nodesWithJoinRequests = NodeEntryLib.nodeAddrsToNodes(allNodes, addrToNodeIndex, nodesWithJoinRequestAddrs);
    
    // Sort the node entries that sent join requests by energy level in descending order
    nodesWithJoinRequests = QuickSort.sort(nodesWithJoinRequests);

    // N_CH calculation:
    // (probability * links.numOfJoinRequests * 100) / 10000
    // where probability is an integer representing a percentage (0 < probability <= 100)
    // and links.numOfJoinRequests >= 1
    numOfClusterHeads = (_probability * 
        (currClusterHead.links.numOfJoinRequests*100)) / 10000; 
    
    // Select the cluster heads from the nodes with join requests
    uint numOfElectedClusterHeads = 0;
    for (uint i = 0; i < nodesWithJoinRequests.length; i++) {
      // If more than 1 cluster head to select: Select N_CH nodes with the highest energy levels as cluster heads
      if (numOfElectedClusterHeads < numOfClusterHeads) {
        // Register the cluster heads
        registerAsClusterHead(_currCHeadAddr, nodesWithJoinRequests[i].nodeAddress);
        numOfElectedClusterHeads++;
      }
      // If all cluster heads have been elected, register the member nodes for this layer
      else {
        registerAsMemberNode(_currCHeadAddr, nodesWithJoinRequests[i].nodeAddress);
      }
    }
  }
  
  /**
   * @notice Simulate getting data from the sensors of the given node.
   * @param _sReading The reading to add 
   * @param _nodeAddr The address of the node to get the sensor readings from
   */
  function readSensorInput(uint256 _sReading, uint _nodeAddr) public {
    uint nodeIndex = getNodeIndex(_nodeAddr);
    DS.SensorReading[] memory sReadings = new DS.SensorReading[](1);
    sReadings[0] = DS.SensorReading(_sReading, true);
    NodeEntryLib.readSensorInput(allNodes[nodeIndex], allNodes, addrToNodeIndex, sReadings);
  }
  
  /**
   * @notice Respond to sensor readings from all children of this node to
             trigger certain actuators. If an actuator's threshold is reached,
             mark the actuator as triggered.
   * @param _nodeAddr Address of node 
   */
  function respondToSensorInput(uint256 _nodeAddr) public {
    uint nodeIndex = getNodeIndex(_nodeAddr);
    NodeEntryLib.respondToSensorInput(allNodes[nodeIndex], allNodes, addrToNodeIndex, nodeRoleEntries, false);
  }

  /**
   * @notice Mark the node with the given address as inactive.
   * @param _nodeAddr Address of node 
   */
  function deactivateNode(uint256 _nodeAddr) public {
    uint nodeIndex = getNodeIndex(_nodeAddr);
    NodeEntryLib.deactivateNode(allNodes[nodeIndex]);
  }
  
  /**
   * @notice Mark the node with the given address as active.
   * @param _nodeAddr Address of node 
   */
  function activateNode(uint256 _nodeAddr) public {
    uint nodeIndex = getNodeIndex(_nodeAddr);
    NodeEntryLib.activateNode(allNodes[nodeIndex]);
  }
}
