// SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/NetworkFormation.sol";
import "../contracts/Structs.sol";

contract TestNetworkFormation {
  // TODO: next step - implement the cluster head election algorithm!

  // The address of the contract to be tested
  NetworkFormation contAddr = NetworkFormation(DeployedAddresses.NetworkFormation());

  // Address of this contract
  address contractAddress = address(this);


  /***********************************************
   * TEST - Sorting
   ***********************************************/
   // Testing the getSortedNodes() function
   // note: address is just a placeholder
  function testSortNodes() public {
    address dummyAddr = 0xdcAD3A6D3569DF655070DEd06CB7A1b2CCd1D3a1;
    contAddr.addNode(1, dummyAddr, 89);
    contAddr.addNode(2, dummyAddr, 71);
    contAddr.addNode(3, dummyAddr, 53);
    contAddr.addNode(4, dummyAddr, 62);
    contAddr.addNode(5, dummyAddr, 90);
    contAddr.addNode(6, dummyAddr, 75);
    contAddr.addNode(7, dummyAddr, 62);
    contAddr.addNode(8, dummyAddr, 52);
    contAddr.addNode(9, dummyAddr, 95);
    contAddr.addNode(10, dummyAddr, 85);
    
    // sort to [95, 90, 89, 85, 75, 71, 62, 62, 53, 52]
    Structs.SensorNode[] memory sortedThingo = contAddr.getSortedNodes();
    Assert.equal(sortedThingo[0].energyLevel, 95, "Sorting error");
    Assert.equal(sortedThingo[1].energyLevel, 90, "Sorting error");
    Assert.equal(sortedThingo[2].energyLevel, 89, "Sorting error");
    Assert.equal(sortedThingo[3].energyLevel, 85, "Sorting error");
    Assert.equal(sortedThingo[4].energyLevel, 75, "Sorting error");
    Assert.equal(sortedThingo[5].energyLevel, 71, "Sorting error");
    Assert.equal(sortedThingo[6].energyLevel, 62, "Sorting error");
    Assert.equal(sortedThingo[7].energyLevel, 62, "Sorting error");
    Assert.equal(sortedThingo[8].energyLevel, 53, "Sorting error");
    Assert.equal(sortedThingo[9].energyLevel, 52, "Sorting error");
  }

  /***********************************************
   * TEST - Getting existing nodes
   ***********************************************/
   address dummyAddr1 = 0xaaAD3A6d3889dF677070DED06db7A1b2CCD1d3a1;
   address dummyAddr2 = 0xBbAD3a6D4489dfe77070DED06DB7a198CCD1D3A2;

  function testGetNode() public {
    contAddr.addNode(100, dummyAddr1, 50);
    contAddr.addNode(101, dummyAddr2, 35);

    Structs.SensorNode memory node100 = contAddr.getNode(dummyAddr1);
    Assert.equal(node100.nodeID, 100, "Retrieval error");
    Assert.equal(node100.nodeAddress, dummyAddr1, "Retrieval error");
    Assert.equal(node100.energyLevel, 50, "Retrieval error");

    Structs.SensorNode memory node101 = contAddr.getNode(dummyAddr2);
    Assert.equal(node101.nodeID, 101, "Retrieval error");
    Assert.equal(node101.nodeAddress, dummyAddr2, "Retrieval error");
    Assert.equal(node101.energyLevel, 35, "Retrieval error");
  }

  /***********************************************
   * TEST - Registration of nodes
   ***********************************************/
  function testNodeRegistration() public {
    // Register dummyAddr1 node as cluster head
    Assert.equal(contAddr.getNode(dummyAddr1).isClusterHead, false, "Cluster head has issues");
    Assert.equal(contAddr.getNode(dummyAddr1).isMemberNode, false, "Cluster head has issues");
    contAddr.registerAsClusterHead(dummyAddr1);
    Assert.equal(contAddr.getNode(dummyAddr1).isClusterHead, true, "Cluster head registration has issues");
    Assert.equal(contAddr.getNode(dummyAddr1).isMemberNode, false, "Cluster head registration has issues");
    // this should fail: contAddr.registerAsMemberNode(dummyAddr2, dummyAddr1);
    
    // Register dummyAddr2 node as member node of cluster with dummyAddr1 as cluster head
    Assert.equal(contAddr.getNode(dummyAddr2).isClusterHead, false, "Node has issues");
    Assert.equal(contAddr.getNode(dummyAddr2).isMemberNode, false, "Node has issues");
    contAddr.registerAsMemberNode(dummyAddr1, dummyAddr2);
    Assert.equal(contAddr.getNode(dummyAddr2).isClusterHead, false, "Member node registration has issues");
    Assert.equal(contAddr.getNode(dummyAddr2).isMemberNode, true, "Member node registration has issues");
    // this should fail: contAddr.registerAsClusterHead(dummyAddr2);
  }

  /***********************************************
   * TEST - Floor division in Solidity
   ***********************************************/
  function testFloor() public {
    uint result1 = uint(12) / 5; // 2.4
    Assert.equal(result1, 2, "Division is not floor?");
    uint result2 = uint(15) / 4; // 3.75
    Assert.equal(result2, 3, "Division is not floor?");
    
    // N_CH calculation experiment:
    // (probability * numOfJoinRequests * 100) / 10000
    // where probability is an integer representing a percentage (0 < probability <= 100)
    // and numOfJoinRequests >= 1
    uint probability = 65;
    uint numOfClusterHeads = (probability * (5*100)) / 10000; 
    Assert.equal(numOfClusterHeads, 3, "Division is not floor?");
    numOfClusterHeads = (probability * (4*100)) / 10000; 
    Assert.equal(numOfClusterHeads, 2, "Division is not floor?");
    numOfClusterHeads = (probability * (3*100)) / 10000; 
    Assert.equal(numOfClusterHeads, 1, "Division is not floor?");
    numOfClusterHeads = (probability * (2*100)) / 10000; 
    Assert.equal(numOfClusterHeads, 1, "Division is not floor?");
    numOfClusterHeads = (probability * (1*100)) / 10000; 
    Assert.equal(numOfClusterHeads, 0, "Division is not floor?");
  }
}
