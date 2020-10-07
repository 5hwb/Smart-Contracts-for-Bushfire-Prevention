// SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "./DS.sol";
import "./QuickSort.sol";
import "./SensorNode.sol";
import "./NodeRoleEntries.sol";

// A smart contract hosted by each sensor node that forms the clustered network. 
contract NodeEntries {
  
  uint numOfClusterHeads; // N_CH
  
  // Array of all nodes in the network
  DS.Node[] public nodes;
  mapping (uint => uint) addrToNodeIndex; // node addresses -> node array index

  uint public numOfNodes; // Number of nodes in this network
  uint public numOfLevels; // How many levels the network is consisted of
  
  // Smart contract for the node role entries
  NodeRoleEntries nodeRoleEntries;
  
  // Events
  event AddedNode(uint256 addr, uint energyLevel, uint networkLevel, DS.NodeType nodeType);
  event SomethingHappened(uint i, uint cHeadAddr, uint nodeAddr, uint numOfWithinRangeNodes, string msg);

  // Set the deployed NodeRoleEntries contract instance to use. 
  function setNodeRoleEntries(NodeRoleEntries _nf2) public {
    nodeRoleEntries = _nf2;
  }
  
  // Get array of all DS.Node instances.
  function getAllNodes() view public returns(DS.Node[] memory) {
    return nodes;
  }
  
  // Get array of addresses of all DS.Node instances.
  function getAllNodeAddresses() view public returns(uint[] memory) {
    uint[] memory nodeAddresses = new uint[](numOfNodes);
    for (uint i = 0; i < numOfNodes; i++) {
      nodeAddresses[i] = nodes[i].nodeAddress;
    }
    return nodeAddresses;
  }
  
  // Add a node to the list of all sensor nodes.
  function addNode(uint _addr, uint _energyLevel, uint[] memory _withinRangeNodes) public {
    // Push a new DS.Node instance onto the array of nodes
    DS.Node storage node = nodes.push();

    // Initialise the empty node's values
    SensorNode.initNodeStruct(node, _addr, _energyLevel);
    for (uint i = 0; i < _withinRangeNodes.length; i++) {
      SensorNode.addWithinRangeNode(node, _withinRangeNodes[i]);
    }
        
    // Add mapping of address to node array index 
    addrToNodeIndex[_addr] = numOfNodes;
    numOfNodes++;

    emit AddedNode(_addr, _energyLevel, node.networkLevel, node.nodeType);
    
    // Call NodeRoleEntries - add an entry as well
    nodeRoleEntries.addNode(_addr);
  }
  
  // Get the index of the node with the given address
  function getNodeIndex(uint _nodeAddr) view public returns(uint) {
    return addrToNodeIndex[_nodeAddr];
  }
  
  // Get the node with the given address
  function getNodeEntry(uint _nodeAddr) view public returns(DS.Node memory) {
    uint nIdx = addrToNodeIndex[_nodeAddr];
    return nodes[nIdx];
  }
  
  // Get the node with the given index
  function getNodeAt(uint _index) view public returns(DS.Node memory) {
    return nodes[_index];
  }
  
  // Get node information
  function getNodeInfo(uint _nodeAddr) public view returns (
    uint256,
    uint, uint,
    DS.NodeType, DS.NodeRole,
    bool, bool, 
    string memory, uint256[] memory
    ) {
    uint nIdx = addrToNodeIndex[_nodeAddr];
    DS.NodeRoleEntry memory nodeRoleEntry = nodeRoleEntries.getNREntry(nodes[nIdx].nodeAddress);
    
    return (nodes[nIdx].nodeAddress, // 0
        nodes[nIdx].energyLevel, nodes[nIdx].networkLevel, // 1, 2
        nodes[nIdx].nodeType, nodeRoleEntry.nodeRole, // 3, 4
        nodes[nIdx].isActive, nodeRoleEntry.isTriggeringExternalService, // 5, 6
        nodeRoleEntry.triggerMessage, SensorNode.getSensorReadings(nodes[nIdx]) // 7, 8
        );
  }
  
  // Get a node's beacon data
  function getNodeBeaconData(uint _nodeAddr) public view returns (
    bool, uint, uint256, uint) {      
    DS.Node storage node = SensorNode.getNode(nodes, addrToNodeIndex, _nodeAddr);
    DS.Beacon memory beacon = SensorNode.getBeacon(node);
    return (beacon.isSent, beacon.nextNetLevel, beacon.senderNodeAddr, node.numOfBeacons);
  }

  // CLUSTER HEAD ONLY - Send beacon to prospective child nodes
  function sendBeacon(uint _cHeadAddr) public {
    uint chIndex = getNodeIndex(_cHeadAddr);
    require(nodes[chIndex].nodeType == DS.NodeType.ClusterHead, "Given node is not cluster head");

    // Get network level of this cluster head to calculate next level
    uint nextNetLevel = nodes[chIndex].networkLevel;
    nextNetLevel++;
    
    // Go thru all nodes within range of the cluster head
    for (uint i = 0; i < SensorNode.numOfWithinRangeNodes(nodes[chIndex]); i++) {
      DS.Node storage currNode = SensorNode.getNode(nodes, addrToNodeIndex, nodes[chIndex].links.withinRangeNodes[i]);
      
      // Ignore this node if it's a cluster head or if the network level is 
      // already set between 1 and the current cluster head's network level 
      if (currNode.nodeType == DS.NodeType.ClusterHead || (currNode.networkLevel > 0
          && currNode.networkLevel <= nodes[chIndex].networkLevel)) {
        emit SomethingHappened(i, nodes[chIndex].nodeAddress, currNode.nodeAddress, SensorNode.numOfWithinRangeNodes(nodes[chIndex]), "Node was ignored");
        continue;
      }

      // Send the beacon!
      emit SomethingHappened(i, nodes[chIndex].nodeAddress, currNode.nodeAddress, SensorNode.numOfWithinRangeNodes(nodes[chIndex]), "Gonna set...");
      SensorNode.setNetworkLevel(currNode, nextNetLevel);
      DS.Beacon memory beacon = DS.Beacon(true, nextNetLevel, nodes[chIndex].nodeAddress, SensorNode.getWithinRangeNodes(nodes[chIndex]));
      SensorNode.addBeacon(currNode, beacon);
    }
  }
  
  // Send a join request to the given cluster head.
  function sendJoinRequest(uint _sensorAddr, uint _cHeadAddr) public {
    uint nodeIndex = getNodeIndex(_sensorAddr);
    DS.Node storage cHeadNode = SensorNode.getNode(nodes, addrToNodeIndex, _cHeadAddr);
    
    // Add this node to cluster head's list of nodes that sent join requests
    assert(cHeadNode.nodeAddress != 0); // make sure the cluster head node exists
    SensorNode.addJoinRequestNode(cHeadNode, nodes[nodeIndex].nodeAddress);
  }
  
  event SentJoinRequest(uint256 _addr, uint _i);
  
  // Go thru all nodes to see if they have received a beacon from a cluster head and need to send a join request back.
  function sendJoinRequests() public {
    for (uint i = 0; i < numOfNodes; i++) {
      emit SentJoinRequest(nodes[i].nodeAddress, i);
      // Send join request to cluster head iff a beacon has been received from that node
      require(nodes[i].beacons.length > 0, "NO BEACONS!??");
      if (SensorNode.getBeacon(nodes[i]).isSent) {
        sendJoinRequest(nodes[i].nodeAddress, SensorNode.getBeacon(nodes[i]).senderNodeAddr);
      }
    }
  }
  
  // Identify the backup cluster heads for each node
  function identifyBackupClusterHeads() public {
    for (uint i = 0; i < numOfNodes; i++) {
      SensorNode.identifyBackupClusterHeads(nodes[i]);
    }
  }
  
  // Register the given node as a cluster head.
  function registerAsClusterHead(uint _parentAddr, uint _nodeAddr) public {
    uint nodeIndex = getNodeIndex(_nodeAddr);
    uint parentIndex = getNodeIndex(_parentAddr);
    assert(nodes[nodeIndex].nodeType == DS.NodeType.Unassigned);
    
    // By default, cluster heads are also Controllers,
    // hence they are assigned to the Controller role.
    SensorNode.setAsClusterHead(nodes[nodeIndex]);
    nodeRoleEntries.assignAsController(nodes[nodeIndex].nodeAddress);
    
    // Set the parent node (only if valid address!) and add this node as the child node of the parent
    if (_parentAddr != 0) {
      SensorNode.setParentNode(nodes[nodeIndex], nodes[parentIndex].nodeAddress);
      SensorNode.addChildNode(nodes[parentIndex], nodes[nodeIndex].nodeAddress);
    }
  }
  
  // Register the given node as a member node of the given cluster head.
  function registerAsMemberNode(uint _parentAddr, uint _nodeAddr) public {
    uint nodeIndex = getNodeIndex(_nodeAddr);
    uint parentIndex = getNodeIndex(_parentAddr);
    assert(nodes[nodeIndex].nodeType == DS.NodeType.Unassigned);

    SensorNode.setAsMemberNode(nodes[nodeIndex]);

    // Set the parent node (only if valid address!) and add this node as the child node of the parent
    if (_parentAddr != 0) {
      SensorNode.setParentNode(nodes[nodeIndex], nodes[parentIndex].nodeAddress);
      SensorNode.addChildNode(nodes[parentIndex], nodes[nodeIndex].nodeAddress);
    }
  }
  
  // Get the sorted nodes 
  function getSortedNodes() public returns(DS.Node[] memory) {
    return QuickSort.sort(nodes);
  }
    
  // Elect the next cluster heads for the next layer using the GCA algorithm as described in Lee et al. (2011) with the given probability.
  function electClusterHeads(uint _currCHeadAddr, uint _probability) public {
  
    // Get the sensor node with the given address
    DS.Node storage currClusterHead = SensorNode.getNode(nodes, addrToNodeIndex, _currCHeadAddr);
    
    // Get the list of addresses of nodes that sent join requests
    // (if its empty, exit the function)
    uint256[] memory nodesWithJoinRequestAddrs = SensorNode.getJoinRequestNodes(currClusterHead);
    if (nodesWithJoinRequestAddrs.length == 0) {
      return;
    }
    
    // Convert list of addresses into their corresponding nodes
    DS.Node[] memory nodesWithJoinRequests = SensorNode.nodeAddrsToNodes(nodes, addrToNodeIndex, nodesWithJoinRequestAddrs);
    
    // Sort the sensor nodes that sent join requests by energy level in descending order
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
  
  // Simulate getting data from the sensors of the given node
  function readSensorInput(uint256 _sReading, uint _nodeAddr) public {
    uint nodeIndex = getNodeIndex(_nodeAddr);
    DS.SensorReading[] memory sReadings = new DS.SensorReading[](1);
    sReadings[0] = DS.SensorReading(_sReading, true);
    SensorNode.readSensorInput(nodes[nodeIndex], nodes, addrToNodeIndex, sReadings);
  }
  
  // Respond to sensor readings from all children of this node 
  function respondToSensorInput(uint256 _nodeAddr) public {
    uint nodeIndex = getNodeIndex(_nodeAddr);
    SensorNode.respondToSensorInput(nodes[nodeIndex], nodes, addrToNodeIndex, nodeRoleEntries, false);
  }

  // Mark the node with the given address as inactive
  function deactivateNode(uint256 _nodeAddr) public {
    uint nodeIndex = getNodeIndex(_nodeAddr);
    SensorNode.deactivateNode(nodes[nodeIndex]);
  }
  
  // Mark the node with the given address as active
  function activateNode(uint256 _nodeAddr) public {
    uint nodeIndex = getNodeIndex(_nodeAddr);
    SensorNode.activateNode(nodes[nodeIndex]);
  }
}
