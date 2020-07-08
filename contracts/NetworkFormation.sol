pragma solidity ^0.5.16;

// A smart contract hosted by each sensor node that forms the clustered network. 
contract NetworkFormation {
  struct SensorNode {
    uint nodeID;                  // ID of the node
    address nodeAddress;          // Ethereum address of the node
    uint energyLevel;             // give it when initialising
    uint numOfOneHopClusterHeads; // init to 1
    
    address parentNode;   // parent (cluster head) of this node
    address[] childNodes; // children of this node (if cluster head)
  }
  
  uint numOfClusterHeads;
  
  SensorNode[] nodes;
  
  function addNode(uint id, address addr) public {
    address[] memory thingo;
    SensorNode memory node = SensorNode(id, addr, 0, 1, address(this), thingo);
    nodes.push(node);
  }
  
  function sendJoinRequest() public {
    // todo
  }
  
  // TODO: implement the GCA algorithm as described in Lee et al. (2011)
  
}
