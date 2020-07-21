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
  
  // Add a node to the list of all sensor nodes.
  function addNode(uint id, address addr, uint energyLevel, address[] memory _withinRangeNodes) public {
    SensorNode node = new SensorNode(id, addr, energyLevel);
    
    for (uint i = 0; i < _withinRangeNodes.length; i++) {
      node.addWithinRangeNode(_withinRangeNodes[i]);
    }
    
    nodes.push(node);
    numOfNodes++;
  }
  
  // Get the index of the node with the given address
  function getNodeIndex(address sensorNode) view public returns(uint) {
    for (uint i = 0; i < numOfNodes; i++) {
      if (nodes[i].nodeAddress() == sensorNode) {
        return i;
      }
    }
  }
  
  // Get the node with the given address
  function getNode(address sensorNode) view public returns(SensorNode) {
    for (uint i = 0; i < numOfNodes; i++) {
      if (nodes[i].nodeAddress() == sensorNode) {
        return nodes[i];
      }
    }
  }
  
  // Convert a list of addresses into their matching sensor nodes
  function addrsToSensorNodes(address[] memory listOfNodes) view public returns(SensorNode[] memory) {
    SensorNode[] memory result = new SensorNode[](listOfNodes.length); 
    for (uint i = 0; i < listOfNodes.length; i++) {
      result[i] = getNode(listOfNodes[i]);
    }
    
    return result;
  }

  // CLUSTER HEAD ONLY - Send beacon to prospective child nodes
  function sendBeacon(address clusterHead) public {
    uint chIndex = getNodeIndex(clusterHead);
    assert(nodes[chIndex].isClusterHead() == true);
    assert(nodes[chIndex].numOfWithinRangeNodes() >= 1);
    
    for (uint i = 0; i < nodes[chIndex].numOfWithinRangeNodes(); i++) {
      SensorNode currNode = getNode(nodes[chIndex].withinRangeNodes(i));
      // Send the beacon!
      // (for now, simulate it by setting the network level integer) 
      numOfLevels++;
      currNode.setNetworkLevel(numOfLevels);
      
      // TODO find out how to do callback function (or equivalent)
      // which shall be: sendJoinRequest(nodes[chIndex].withinRangeNodes[i], clusterHead); 
    }
  }
  
  // Send a join request to cluster head.
  function sendJoinRequest(address sensorNode, address clusterHead) public {
    uint nodeIndex = getNodeIndex(sensorNode);
    uint chIndex = getNodeIndex(clusterHead);
    
    // Add this node to cluster head's list of nodes that sent join requests
    SensorNode cHeadNode = nodes[chIndex];
    assert(cHeadNode.nodeID() != 0); // make sure the cluster head node exists
    cHeadNode.addJoinRequestNode(nodes[nodeIndex].nodeAddress());
  }
  
  // Register the given node as a cluster head.
  function registerAsClusterHead(address sensorNode) public {
    uint nodeIndex = getNodeIndex(sensorNode);
    assert(nodes[nodeIndex].isClusterHead() == false);
    assert(nodes[nodeIndex].isMemberNode() == false);
    nodes[nodeIndex].setAsClusterHead();
  }
  
  // Register the given node as a member node of the given cluster head.
  function registerAsMemberNode(address clusterHead, address sensorNode) public {
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
  function electClusterHeads(address clusterHead, address sensorNode) public {
  
    // Get the sensor node with the given address
    SensorNode currClusterHead = getNode(sensorNode);
    
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
        registerAsMemberNode(clusterHead, nodesWithJoinRequests[i].nodeAddress());
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
