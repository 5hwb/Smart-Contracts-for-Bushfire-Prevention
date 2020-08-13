// SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/NetworkFormation.sol";
import "../contracts/DS.sol";
import "../contracts/SensorNode.sol";

contract TestNetworkFormation {
  // TODO: next step - implement the cluster head election algorithm!

  // The address of the contract to be tested
  NetworkFormation contAddr = NetworkFormation(DeployedAddresses.NetworkFormation());

  // Address of this contract
  address contractAddress = address(this);

  /***********************************************
   * TEST - Sorting
   ***********************************************/
   // PROBLEM: this function fails if I add another function to SensorNode contract! WHY?
   // Testing the getSortedNodes() function
   // note: address is just a placeholder
  // uint256 dummyAddr = 888999777;
  // function testSortNodes() public {
  //   uint[] memory dummyAddrs = new uint[](1);
  //   dummyAddrs[0] = dummyAddr;
  //   contAddr.addNode(1, dummyAddr, 53, dummyAddrs);  // 3
  //   contAddr.addNode(2, dummyAddr, 62, dummyAddrs);  // 2
  //   contAddr.addNode(3, dummyAddr, 89, dummyAddrs);  // 0
  //   contAddr.addNode(4, dummyAddr, 71, dummyAddrs);  // 1
  // 
  //   // sort to [89, 71, 62, 53]
  //   SensorNode[] memory sortedThingo = contAddr.getSortedNodes();
  //   // Check that nodes have been sorted by their energy levels in descending order
  //   Assert.equal(sortedThingo[0].energyLevel(), 89, "Sorting error");
  //   Assert.equal(sortedThingo[1].energyLevel(), 71, "Sorting error");
  //   Assert.equal(sortedThingo[2].energyLevel(), 62, "Sorting error");
  //   Assert.equal(sortedThingo[3].energyLevel(), 53, "Sorting error");
  //   // Another check to ensure the IDs are correct
  //   Assert.equal(sortedThingo[0].nodeID(), 3, "Sorting error - wrong ID");
  //   Assert.equal(sortedThingo[1].nodeID(), 4, "Sorting error - wrong ID");
  //   Assert.equal(sortedThingo[2].nodeID(), 2, "Sorting error - wrong ID");
  //   Assert.equal(sortedThingo[3].nodeID(), 1, "Sorting error - wrong ID");
  // }

  /***********************************************
   * TEST - Getting existing nodes
   ***********************************************/
  //address dummyAddr1 = 0xaaAD3A6d3889dF677070DED06db7A1b2CCD1d3a1;
  //address dummyAddr2 = 0xBbAD3a6D4489dfe77070DED06DB7a198CCD1D3A2;
  uint256 dummyAddr1 = 111222333;
  uint256 dummyAddr2 = 333444555;

  function testGetNode() public {
    uint[] memory dummyAddrs1 = new uint[](1);
    dummyAddrs1[0] = dummyAddr2;
    uint[] memory dummyAddrs2 = new uint[](1);
    dummyAddrs2[0] = dummyAddr1;
    contAddr.addNode(100, dummyAddr1, 50, dummyAddrs1);
    contAddr.addNode(101, dummyAddr2, 35, dummyAddrs2);

    SensorNode node100 = contAddr.getNode(dummyAddr1);
    Assert.equal(node100.nodeID(), 100, "Retrieval error");
    Assert.equal(node100.nodeAddress(), dummyAddr1, "Retrieval error");
    Assert.equal(node100.energyLevel(), 50, "Retrieval error");

    SensorNode node101 = contAddr.getNode(dummyAddr2);
    Assert.equal(node101.nodeID(), 101, "Retrieval error");
    Assert.equal(node101.nodeAddress(), dummyAddr2, "Retrieval error");
    Assert.equal(node101.energyLevel(), 35, "Retrieval error");
  }

  /***********************************************
   * TEST - Registration of nodes
   ***********************************************/
  function testNodeRegistration() public {
    // Register dummyAddr1 node as cluster head
    Assert.equal(contAddr.getNode(dummyAddr1).isClusterHead(), false, "Cluster head has issues");
    Assert.equal(contAddr.getNode(dummyAddr1).isMemberNode(), false, "Cluster head has issues");
    contAddr.registerAsClusterHead(0, dummyAddr1);
    Assert.equal(contAddr.getNode(dummyAddr1).isClusterHead(), true, "Cluster head registration has issues");
    Assert.equal(contAddr.getNode(dummyAddr1).isMemberNode(), false, "Cluster head registration has issues");
    // this should fail: contAddr.registerAsMemberNode(dummyAddr2, dummyAddr1);
    
    // Register dummyAddr2 node as member node of cluster with dummyAddr1 as cluster head
    Assert.equal(contAddr.getNode(dummyAddr2).isClusterHead(), false, "Node has issues");
    Assert.equal(contAddr.getNode(dummyAddr2).isMemberNode(), false, "Node has issues");
    contAddr.registerAsMemberNode(dummyAddr1, dummyAddr2);
    Assert.equal(contAddr.getNode(dummyAddr2).isClusterHead(), false, "Member node registration has issues");
    Assert.equal(contAddr.getNode(dummyAddr2).isMemberNode(), true, "Member node registration has issues");
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
