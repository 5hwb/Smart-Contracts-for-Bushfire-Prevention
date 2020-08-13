// SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "./DS.sol";
import "./SensorNode.sol";

// A smart contract hosted by each sensor node that forms the clustered network. 
contract NetworkFormation {
  
  uint numOfClusterHeads; // N_CH
  
  // Array of all nodes in the network
  SensorNode[] public nodes;
  mapping (uint => uint) addrToNodeIndex; // node addresses -> node array index

  uint public numOfNodes; // Number of nodes in this network
  uint public numOfLevels; // How many levels the network is consisted of
  
  // Events
  event AddedNode(uint nodeID, uint256 addr, uint energyLevel, uint networkLevel, bool isClusterHead, bool isMemberNode);
  event SomethingHappened(uint i, uint cHeadAddr, uint nodeAddr, uint numOfWithinRangeNodes, string msg);
  
  // Get array of all SensorNode instances.
  function getAllNodes() view public returns(SensorNode[] memory) {
    return nodes;
  }
  
  // Get array of addresses of all SensorNode instances.
  function getAllNodeAddresses() view public returns(uint[] memory) {
    uint[] memory nodeAddresses = new uint[](numOfNodes);
    for (uint i = 0; i < numOfNodes; i++) {
      nodeAddresses[i] = nodes[i].nodeAddress();
    }
    return nodeAddresses;
  }
  
  // Add a node to the list of all sensor nodes.
  function addNode(uint _id, uint _addr, uint _energyLevel, uint[] memory _withinRangeNodes) public {
    SensorNode node = new SensorNode(_id, _addr, _energyLevel);
    
    for (uint i = 0; i < _withinRangeNodes.length; i++) {
      node.addWithinRangeNode(_withinRangeNodes[i]);
    }
    
    // Add mapping of address to node array index 
    addrToNodeIndex[_addr] = numOfNodes;
    nodes.push(node);
    numOfNodes++;
    emit AddedNode(_id, _addr, _energyLevel, node.networkLevel(), node.isClusterHead(), node.isMemberNode());
  }
  
  // Get the index of the node with the given address
  function getNodeIndex(uint _nodeAddr) view public returns(uint) {
    return addrToNodeIndex[_nodeAddr];
  }
  
  // Get the node with the given address
  function getNode(uint _nodeAddr) view public returns(SensorNode) {
    uint nIdx = addrToNodeIndex[_nodeAddr];
    return nodes[nIdx];
  }
  
  // Get node information
  function getNodeInfo(uint _nodeAddr) public view returns (
    uint, uint256,
    uint, uint,
    bool, bool,
    uint256[] memory) {
      
    uint nIdx = addrToNodeIndex[_nodeAddr];
    return (nodes[nIdx].nodeID(), nodes[nIdx].nodeAddress(),
        nodes[nIdx].energyLevel(), nodes[nIdx].networkLevel(),
        nodes[nIdx].isClusterHead(), nodes[nIdx].isMemberNode(),
        nodes[nIdx].getSensorReadings());
  }
  
  // Get a node's beacon data
  function getNodeBeaconData(uint _nodeAddr) public view returns (
    bool, uint, uint256, uint) {
      
    SensorNode node = getNode(_nodeAddr);
    DS.Beacon memory beacon = node.getBeacon();
    return (beacon.isSent, beacon.nextNetLevel, beacon.senderNodeAddr, node.numOfBeacons());
  }
  
  // Convert a list of addresses into their matching sensor nodes
  function addrsToSensorNodes(uint[] memory _listOfNodeAddrs) view public returns(SensorNode[] memory) {
    SensorNode[] memory result = new SensorNode[](_listOfNodeAddrs.length); 
    for (uint i = 0; i < _listOfNodeAddrs.length; i++) {
      result[i] = getNode(_listOfNodeAddrs[i]);
    }
    
    return result;
  }

  // CLUSTER HEAD ONLY - Send beacon to prospective child nodes
  function sendBeacon(uint _cHeadAddr) public {
    uint chIndex = getNodeIndex(_cHeadAddr);
    require(nodes[chIndex].isClusterHead() == true, "Given node is not cluster head");

    // Get network level of this cluster head to calculate next level
    uint nextNetLevel = nodes[chIndex].networkLevel();
    nextNetLevel++;
    
    // Go thru all nodes within range of the cluster head
    for (uint i = 0; i < nodes[chIndex].numOfWithinRangeNodes(); i++) {
      SensorNode currNode = getNode(nodes[chIndex].withinRangeNodes(i));
      
      // Ignore this node if it's a cluster head or if the network level is 
      // already set between 1 and the current cluster head's network level 
      if (currNode.isClusterHead() || (currNode.networkLevel() > 0
          && currNode.networkLevel() <= nodes[chIndex].networkLevel())) {
        emit SomethingHappened(i, nodes[chIndex].nodeAddress(), currNode.nodeAddress(), nodes[chIndex].numOfWithinRangeNodes(), "Node was ignored");
        continue;
      }

      // Send the beacon!
      // (for now, simulate it by setting the network level integer) 
      emit SomethingHappened(i, nodes[chIndex].nodeAddress(), currNode.nodeAddress(), nodes[chIndex].numOfWithinRangeNodes(), "Gonna set...");
      currNode.setNetworkLevel(nextNetLevel);
      DS.Beacon memory beacon = DS.Beacon(true, nextNetLevel, nodes[chIndex].nodeAddress(), nodes[chIndex].getWithinRangeNodes());
      currNode.addBeacon(beacon);
      
      // TODO find out how to do callback function (or equivalent)
      // which shall be: sendJoinRequest(nodes[chIndex].withinRangeNodes[i], _cHeadAddr); 
    }
  }
  
  // Send a join request to the given cluster head.
  function sendJoinRequest(uint _sensorAddr, uint _cHeadAddr) public {
    uint nodeIndex = getNodeIndex(_sensorAddr);
    SensorNode cHeadNode = getNode(_cHeadAddr);
    
    // Add this node to cluster head's list of nodes that sent join requests
    assert(cHeadNode.nodeID() != 0); // make sure the cluster head node exists
    cHeadNode.addJoinRequestNode(nodes[nodeIndex]);
  }
  
  // Go thru all nodes to see if they have received a beacon from a cluster head and need to send a join request back.
  function sendJoinRequests() public {
    for (uint i = 0; i < numOfNodes; i++) {
      // For now: Send join request iff the network level has been changed
      // to a value other than 0
      if (nodes[i].getBeacon().isSent) {
        sendJoinRequest(nodes[i].nodeAddress(), nodes[i].getBeacon().senderNodeAddr);
      }
    }
  }
  
  // Register the given node as a cluster head.
  function registerAsClusterHead(uint _cHeadAddr, uint _nodeAddr) public {
    uint nodeIndex = getNodeIndex(_nodeAddr);
    uint cHeadIndex = getNodeIndex(_cHeadAddr);
    assert(nodes[nodeIndex].isClusterHead() == false);
    assert(nodes[nodeIndex].isMemberNode() == false);
    
    nodes[nodeIndex].setAsClusterHead();
    
    // Set the cluster head as the parent node (only if valid address!)
    if (_cHeadAddr != 0) {
      nodes[nodeIndex].setParentNode(nodes[cHeadIndex]);
    }
  }
  
  // Register the given node as a member node of the given cluster head.
  function registerAsMemberNode(uint _cHeadAddr, uint _nodeAddr) public {
    uint nodeIndex = getNodeIndex(_nodeAddr);
    uint cHeadIndex = getNodeIndex(_cHeadAddr);
    assert(nodes[nodeIndex].isClusterHead() == false);
    assert(nodes[nodeIndex].isMemberNode() == false);

    nodes[nodeIndex].setAsMemberNode();
    nodes[nodeIndex].setParentNode(nodes[cHeadIndex]);
  }
  
  // Get the sorted nodes 
  function getSortedNodes() public returns(SensorNode[] memory) {
    return sort(nodes);
  }
    
  // Elect the next cluster heads for the next layer using the GCA algorithm as described in Lee et al. (2011) with the given probability.
  function electClusterHeads(uint _currCHeadAddr, uint _probability) public {
  
    // Get the sensor node with the given address
    SensorNode currClusterHead = getNode(_currCHeadAddr);
    
    // Get the list of nodes that sent join requests
    // (if its empty, exit the function)
    SensorNode[] memory nodesWithJoinRequests = currClusterHead.getJoinRequestNodes();
    if (nodesWithJoinRequests.length == 0) {
      return;
    }
    
    // Sort the sensor nodes that sent join requests by energy level in descending order
    nodesWithJoinRequests = sort(nodesWithJoinRequests);

    // N_CH calculation:
    // (probability * numOfJoinRequests * 100) / 10000
    // where probability is an integer representing a percentage (0 < probability <= 100)
    // and numOfJoinRequests >= 1
    numOfClusterHeads = (_probability * 
        (currClusterHead.numOfJoinRequests()*100)) / 10000; 
    
    // Select the cluster heads from the nodes with join requests
    uint numOfElectedClusterHeads = 0;
    for (uint i = 0; i < nodesWithJoinRequests.length; i++) {
      // If more than 1 cluster head to select: Select N_CH nodes with the highest energy levels as cluster heads
      if (numOfElectedClusterHeads < numOfClusterHeads) {
        // Register the cluster heads
        registerAsClusterHead(_currCHeadAddr, nodesWithJoinRequests[i].nodeAddress());
        numOfElectedClusterHeads++;
      }
      // If all cluster heads have been elected, register the member nodes for this layer
      else {
        registerAsMemberNode(_currCHeadAddr, nodesWithJoinRequests[i].nodeAddress());
      }
    }
  }
  
  // Simulate getting data from the sensors of the given node
  function readSensorInput(uint256 _sReading, uint _nodeAddr) public {
    uint nodeIndex = getNodeIndex(_nodeAddr);
    DS.SensorReading[] memory sReadings = new DS.SensorReading[](1);
    sReadings[0] = DS.SensorReading(_sReading, true);
    nodes[nodeIndex].readSensorInput(sReadings);
  }
  
  // Sort function for SensorNode arrays that sorts by energy level in descending order.
  // From here: https://gist.github.com/subhodi/b3b86cc13ad2636420963e692a4d896f
  function sort(SensorNode[] memory _data) public returns(SensorNode[] memory) {
     quickSort(_data, int(0), int(_data.length - 1));
     return _data;
  }
  
  function quickSort(SensorNode[] memory _arr, int _left, int _right) internal {
      int i = _left;
      int j = _right;
      if(i==j) return;
      uint pivot = _arr[uint(_left + (_right - _left) / 2)].energyLevel();
      while (i <= j) {
          while (_arr[uint(i)].energyLevel() > pivot) i++;
          while (pivot > _arr[uint(j)].energyLevel()) j--;
          if (i <= j) {
              SensorNode temp = _arr[uint(i)];
              _arr[uint(i)] = _arr[uint(j)];
              _arr[uint(j)] = temp;
              i++;
              j--;
          }
      }
      if (_left < j)
          quickSort(_arr, _left, j);
      if (i < _right)
          quickSort(_arr, i, _right);
  }
}
