// SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "./Structs.sol";
import "./SensorNode.sol";

// A smart contract hosted by each sensor node that forms the clustered network. 
contract NetworkFormation {
  
  uint numOfClusterHeads; // N_CH
  
  // TODO change this to a mapping + list - this article can help: https://ethereum.stackexchange.com/questions/15337/can-we-get-all-elements-stored-in-a-mapping-in-the-contract
  SensorNode[] public nodes;
  
  uint public numOfNodes; // Number of nodes in this network
  uint public numOfLevels; // How many levels the network is consisted of
  
  // Events
  event AddedNode(uint nodeID, uint256 addr, uint energyLevel, uint networkLevel, bool isClusterHead, bool isMemberNode);
  
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
  function addNode(uint id, uint addr, uint energyLevel, uint[] memory _withinRangeNodes) public {
    SensorNode node = new SensorNode(id, addr, energyLevel);
    
    for (uint i = 0; i < _withinRangeNodes.length; i++) {
      node.addWithinRangeNode(_withinRangeNodes[i]);
    }
    
    nodes.push(node);
    numOfNodes++;
    emit AddedNode(id, addr, energyLevel, node.networkLevel(), node.isClusterHead(), node.isMemberNode());
  }
  
  // Get the index of the node with the given address
  function getNodeIndex(uint sensorNode) view public returns(uint) {
    for (uint i = 0; i < numOfNodes; i++) {
      if (nodes[i].nodeAddress() == sensorNode) {
        return i;
      }
    }
  }
  
  // Get the node with the given address
  function getNode(uint sensorNode) view public returns(SensorNode) {
    for (uint i = 0; i < numOfNodes; i++) {
      if (nodes[i].nodeAddress() == sensorNode) {
        return nodes[i];
      }
    }
  }
  
  // returns node information
  function getNodeInfo(uint sensorNodeAddr) public view returns (
    uint, uint256,
    uint, uint,
    bool, bool) {
    for (uint i = 0; i < numOfNodes; i++) {
      if (nodes[i].nodeAddress() == sensorNodeAddr) {
        return (nodes[i].nodeID(), nodes[i].nodeAddress(),
            nodes[i].energyLevel(), nodes[i].networkLevel(),
            nodes[i].isClusterHead(), nodes[i].isMemberNode());
      }
    }
  }
  
  // Convert a list of addresses into their matching sensor nodes
  function addrsToSensorNodes(uint[] memory listOfNodes) view public returns(SensorNode[] memory) {
    SensorNode[] memory result = new SensorNode[](listOfNodes.length); 
    for (uint i = 0; i < listOfNodes.length; i++) {
      result[i] = getNode(listOfNodes[i]);
    }
    
    return result;
  }

  // CLUSTER HEAD ONLY - Send beacon to prospective child nodes
  function sendBeacon(uint clusterHead) public {
    uint chIndex = getNodeIndex(clusterHead);
    require(nodes[chIndex].isClusterHead() == true, "Given node is not cluster head");

    // Get network level of this cluster head to calculate next level
    uint nextNetLevel = nodes[chIndex].networkLevel();
    nextNetLevel++;
    
    for (uint i = 0; i < nodes[chIndex].numOfWithinRangeNodes(); i++) {
      SensorNode currNode = getNode(nodes[chIndex].withinRangeNodes(i));

      // Send the beacon!
      // (for now, simulate it by setting the network level integer) 
      currNode.setNetworkLevel(nextNetLevel);
      
      // TODO find out how to do callback function (or equivalent)
      // which shall be: sendJoinRequest(nodes[chIndex].withinRangeNodes[i], clusterHead); 
    }
  }
  
  // Send a join request to cluster head.
  function sendJoinRequest(uint sensorNode, uint clusterHead) public {
    uint nodeIndex = getNodeIndex(sensorNode);
    uint chIndex = getNodeIndex(clusterHead);
    
    // Add this node to cluster head's list of nodes that sent join requests
    SensorNode cHeadNode = nodes[chIndex];
    assert(cHeadNode.nodeID() != 0); // make sure the cluster head node exists
    cHeadNode.addJoinRequestNode(nodes[nodeIndex].nodeAddress());
  }
  
  // Go thru all nodes to see if they need to send join request to the given cluster head.
  function sendJoinRequests(uint clusterHeadAddr) public {
    for (uint i = 0; i < numOfNodes; i++) {
      // For now: Send join request iff the network level has been changed
      // to a value other than 0
      if (nodes[i].networkLevel() > 0) {
        sendJoinRequest(nodes[i].nodeAddress(), clusterHeadAddr);
      }
    }
  }
  
  // Register the given node as a cluster head.
  function registerAsClusterHead(uint sensorNode) public {
    uint nodeIndex = getNodeIndex(sensorNode);
    assert(nodes[nodeIndex].isClusterHead() == false);
    assert(nodes[nodeIndex].isMemberNode() == false);
    nodes[nodeIndex].setAsClusterHead();
  }
  
  // Register the given node as a member node of the given cluster head.
  function registerAsMemberNode(uint clusterHead, uint sensorNode) public {
    uint nodeIndex = getNodeIndex(sensorNode);

    assert(nodes[nodeIndex].isClusterHead() == false);
    assert(nodes[nodeIndex].isMemberNode() == false);

    nodes[nodeIndex].setAsMemberNode();
    nodes[nodeIndex].setParentNode(clusterHead);
  }
  
  // Get the sorted nodes 
  function getSortedNodes() public returns(SensorNode[] memory) {
    return sort(nodes);
  }
    
  // Elect the next cluster heads for the next layer.
  // NOTE: this may not compile but the basic logic is good
  function electClusterHeads(uint currClusterHeadAddr) public {
  
    // Get the sensor node with the given address
    SensorNode currClusterHead = getNode(currClusterHeadAddr);
    
    // sort the sensor nodes that sent join requests by energy level in descending order
    SensorNode[] memory nodesWithJoinRequests = sort(addrsToSensorNodes(currClusterHead.getJoinRequestNodes()));

    // N_CH calculation:
    // (probability * numOfJoinRequests * 100) / 10000
    // where probability is an integer representing a percentage (0 < probability <= 100)
    // and numOfJoinRequests >= 1
    uint probability = 65; // 65% chance of being elected?
    numOfClusterHeads = (probability * 
        (currClusterHead.numOfJoinRequests()*100)) / 10000; 
    
    // Select the cluster heads from the nodes with join requests
    uint numOfElectedClusterHeads = 0;
    for (uint i = 0; i < nodesWithJoinRequests.length; i++) {
      // If more than 1 cluster head to select: Select N_CH nodes with the highest energy levels as cluster heads
      if (numOfElectedClusterHeads < numOfClusterHeads) {
        // Register the cluster heads
        registerAsClusterHead(nodesWithJoinRequests[i].nodeAddress());
        numOfElectedClusterHeads++;
      }
      // If all cluster heads have been elected, register the member nodes for this layer
      else {
        registerAsMemberNode(currClusterHeadAddr, nodesWithJoinRequests[i].nodeAddress());
      }
    }
  }
  
  // TODO: implement the GCA algorithm as described in Lee et al. (2011)
  
  
  // Sort function for SensorNode arrays that sorts by energy level in descending order.
  // From here: https://gist.github.com/subhodi/b3b86cc13ad2636420963e692a4d896f
  function sort(SensorNode[] memory data) public returns(SensorNode[] memory) {
     quickSort(data, int(0), int(data.length - 1));
     return data;
  }
  
  function quickSort(SensorNode[] memory arr, int left, int right) internal {
      int i = left;
      int j = right;
      if(i==j) return;
      uint pivot = arr[uint(left + (right - left) / 2)].energyLevel();
      while (i <= j) {
          while (arr[uint(i)].energyLevel() > pivot) i++;
          while (pivot > arr[uint(j)].energyLevel()) j--;
          if (i <= j) {
              //(arr[uint(i)].energyLevel(), arr[uint(j)].energyLevel()) = (arr[uint(j)].energyLevel(), arr[uint(i)].energyLevel());
              uint temp = arr[uint(i)].energyLevel();
              arr[uint(i)].setEnergyLevel(arr[uint(j)].energyLevel());
              arr[uint(j)].setEnergyLevel(temp);
              i++;
              j--;
          }
      }
      if (left < j)
          quickSort(arr, left, j);
      if (i < right)
          quickSort(arr, i, right);
  }
}
