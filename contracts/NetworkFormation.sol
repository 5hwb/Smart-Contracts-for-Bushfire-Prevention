// SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "./Structs.sol";

// A smart contract hosted by each sensor node that forms the clustered network. 
contract NetworkFormation {
  
  uint numOfClusterHeads; // N_CH
  
  // TODO change this to a mapping + list - this article can help: https://ethereum.stackexchange.com/questions/15337/can-we-get-all-elements-stored-in-a-mapping-in-the-contract
  Structs.SensorNode[] public nodes;
  uint public numOfNodes;
  
  // Add a node to the list of all sensor nodes.
  function addNode(uint id, address addr, uint energyLevel) public {
    address[] memory thingo; // a dummy address list
    Structs.SensorNode memory node = Structs.SensorNode(
      id, addr, energyLevel, // nodeID, nodeAddress, energyLevel 
      1, // numOfOneHopClusterHeads
      false, // isClusterHead
      false, //isMemberNode
      address(this), // parentNode (DUMMY PLACEMENT FOR NOW)
      thingo, // childNodes (DUMMY PLACEMENT FOR NOW)
      thingo, // joinRequestNodes (DUMMY PLACEMENT FOR NOW)
      0 // numOfJoinRequests
    );
    nodes.push(node);
    numOfNodes++;
  }
  
  // Get the node with the given address
  function getNode(address sensorNode) view public returns(Structs.SensorNode memory) {
    for (uint i = 0; i < numOfNodes; i++) {
      if (nodes[i].nodeAddress == sensorNode) {
        return nodes[i];
      }
    }
  }
  
  // Convert a list of addresses into their matching sensor nodes
  function addrsToSensorNodes(address[] memory listOfNodes) view public returns(Structs.SensorNode[] memory) {
    Structs.SensorNode[] memory result = new Structs.SensorNode[](listOfNodes.length); 
    for (uint i = 0; i < listOfNodes.length; i++) {
      result[i] = getNode(listOfNodes[i]);
    }
    
    return result;
  }

  // CLUSTER HEAD ONLY - Send beacon to prospective child nodes
  function sendBeacon() public {
    // todo
  }
  
  // Send a join request to cluster head.
  function sendJoinRequest(address sensorNode, address clusterHead) public {
    // todo
  }
  
  // Register the given node as a cluster head.
  function registerAsClusterHead(address sensorNode) public {
    // todo
  }
  
  // Register the given node as a member node of the given cluster head.
  function registerAsMemberNode(address clusterHead, address sensorNode) public {
    // todo
  }
  
  // Get the sorted nodes 
  function getSortedNodes() public returns(Structs.SensorNode[] memory) {
    return sort(nodes);
  }
    
  // Elect the next cluster heads for the next layer.
  // NOTE: this may not compile but the basic logic is good
  function electClusterHeads(address clusterHead, address sensorNode) public {
  
    // Get the sensor node with the given address
    Structs.SensorNode memory currClusterHead = getNode(sensorNode);
    
    // sort the sensor nodes that sent join requests by energy level in descending order
    Structs.SensorNode[] memory nodesWithJoinRequests = sort(addrsToSensorNodes(currClusterHead.joinRequestNodes));

    // N_CH calculation:
    // (probability * numOfJoinRequests * 100) / 10000
    // where probability is an integer representing a percentage (0 < probability <= 100)
    // and numOfJoinRequests >= 1
    uint probability = 65; // 65% chance of being elected?
    numOfClusterHeads = (probability * 
        (currClusterHead.numOfJoinRequests*100)) / 10000; 
    
    // Select the cluster heads from the nodes with join requests
    uint numOfElectedClusterHeads = 0;
    for (uint i = 0; i < nodesWithJoinRequests.length; i++) {
      // If more than 1 cluster head to select: Select N_CH nodes with the highest energy levels as cluster heads
      if (numOfElectedClusterHeads < numOfClusterHeads) {
        // Register the cluster heads
        registerAsClusterHead(nodesWithJoinRequests[i].nodeAddress);
        numOfElectedClusterHeads++;
      } else {
        registerAsMemberNode(clusterHead, nodesWithJoinRequests[i].nodeAddress);
      }
    }
      
    // Register the member nodes for this layer
  }
  
  // TODO: implement the GCA algorithm as described in Lee et al. (2011)
  
  
  // Sort function for SensorNode arrays that sorts by energy level in descending order.
  // From here: https://gist.github.com/subhodi/b3b86cc13ad2636420963e692a4d896f
  function sort(Structs.SensorNode[] memory data) public returns(Structs.SensorNode[] memory) {
     quickSort(data, int(0), int(data.length - 1));
     return data;
  }
  
  function quickSort(Structs.SensorNode[] memory arr, int left, int right) internal {
      int i = left;
      int j = right;
      if(i==j) return;
      uint pivot = arr[uint(left + (right - left) / 2)].energyLevel;
      while (i <= j) {
          while (arr[uint(i)].energyLevel > pivot) i++;
          while (pivot > arr[uint(j)].energyLevel) j--;
          if (i <= j) {
              (arr[uint(i)].energyLevel, arr[uint(j)].energyLevel) = (arr[uint(j)].energyLevel, arr[uint(i)].energyLevel);
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
