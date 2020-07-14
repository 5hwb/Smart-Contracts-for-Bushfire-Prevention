// SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;

library Structs {
  struct SensorNode {
    uint nodeID;                  // ID of the node
    address nodeAddress;          // Ethereum address of the node
    uint energyLevel;             // give it when initialising
    uint numOfOneHopClusterHeads; // init to 1
    bool isClusterHead;           // init to false
    bool isMemberNode;           // init to false
    
    address parentNode;   // parent (cluster head) of this node
    address[] childNodes; // children of this node (if cluster head)
    address[] joinRequestNodes; // nodes that have sent join requests to this node
    uint numOfJoinRequests; // N_T
  }
}
