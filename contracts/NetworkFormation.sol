// SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "./Structs.sol";

// A smart contract hosted by each sensor node that forms the clustered network. 
contract NetworkFormation {
  
  uint numOfClusterHeads; // N_CH
  uint numOfJoinRequests; // N_T
  
  // TODO change this to a mapping + list - this article can help: https://ethereum.stackexchange.com/questions/15337/can-we-get-all-elements-stored-in-a-mapping-in-the-contract
  Structs.SensorNode[] public nodes;
  
  // Add a node to the list of all sensor nodes.
  function addNode(uint id, address addr, uint energyLevel) public {
    address[] memory thingo; // a dummy address list
    Structs.SensorNode memory node = Structs.SensorNode(id, addr, energyLevel, 1, false, address(this), thingo, thingo);
    nodes.push(node);
  }
  
  // CLUSTER HEAD ONLY - Send beacon to prospective child nodes
  function sendBeacon() public {
    // todo
  }
  
  // Send a join request to cluster head.
  function sendJoinRequest(address clusterHead) public {
    // todo
  }
  
  // Register the given node as a cluster head.
  function registerAsClusterHead(address sensorNode) public {
    // todo
  }
  
  function getSortedNode() public returns(Structs.SensorNode[] memory) {
    return sort(nodes);
  }
  
  // // Elect the next cluster heads for the next layer.
  // // NOTE: this may not compile but the basic logic is good
  // function electClusterHeads(address sensorNode) public {
  // 
  //   Structs.SensorNode currClusterHead = getNode(sensorNode); // placeholder until I do it
  // 
  //   // sort the sensor nodes that sent join requests by energy level in descending order
  //   // TODO: find out how to sort by energy level!
  //   Structs.SensorNode[] memory nodesWithJoinRequests = currClusterHead.joinRequestNodes;
  //   nodesWithJoinRequests.sort();
  // 
  //   uint probability = 65; // 65% chance of being elected?
  // 
  //   // TODO: find out how to calculate floor operation in Solidity
  //   numOfClusterHeads = floor((probability / 100) * numOfJoinRequests); // N_CH
  // 
  //   // Select the cluster heads
  //   uint memory numOfElectedClusterHeads = 0;
  //   address[] chosenClusterHeads;
  //   for (uint i = 0; i < nodesWithJoinRequests.length; i++) {
  //     // If more than 1 cluster head to select: Select N_CH nodes with the highest energy levels as cluster heads
  //     if (numOfClusterHeads > 1) {
  // 
  //       // Get only the top N_CH nodes
  //       if (numOfElectedClusterHeads < numOfClusterHeads) {
  //         chosenClusterHeads.push(nodesWithJoinRequests[i]);
  //         numOfClusterHeadsToElect++;
  //       }
  //     }
  //     // If only 1 cluster head: Select the node with the highest energy level as a cluster head.
  //     else {
  //       chosenClusterHeads.push(nodesWithJoinRequests[i]);
  //     }
  //   }
  // 
  //   // Register the cluster heads
  //   for (uint i = 0; i < numOfClusterHeads; i++) {
  //     registerAsClusterHead(chosenClusterHeads[i]);
  //   }
  // 
  //   // Register the member nodes for this layer
  //   // TODO
  // }
  
  // TODO: implement the GCA algorithm as described in Lee et al. (2011)
  
  
  // Sort function for integer arrays.
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
          while (arr[uint(i)].energyLevel < pivot) i++;
          while (pivot < arr[uint(j)].energyLevel) j--;
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
