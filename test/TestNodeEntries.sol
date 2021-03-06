// SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/NodeEntries.sol";
import "../contracts/DS.sol";
import "../contracts/NodeEntryLib.sol";

contract TestNodeEntries {
  // The address of the contract to be tested
  NodeEntries contAddr = NodeEntries(DeployedAddresses.NodeEntries());

  // Address of this contract
  address contractAddress = address(this);

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
    contAddr.addNode(dummyAddr1, 50, dummyAddrs1);
    contAddr.addNode(dummyAddr2, 35, dummyAddrs2);

    DS.Node memory node100 = contAddr.getNodeEntry(dummyAddr1);
    Assert.equal(node100.nodeAddress, dummyAddr1, "Retrieval error");
    Assert.equal(node100.energyLevel, 50, "Retrieval error");

    DS.Node memory node101 = contAddr.getNodeEntry(dummyAddr2);
    Assert.equal(node101.nodeAddress, dummyAddr2, "Retrieval error");
    Assert.equal(node101.energyLevel, 35, "Retrieval error");
  }

  /***********************************************
   * TEST - Registration of nodes
   ***********************************************/
  function testNodeRegistration() public {
    // Register dummyAddr1 node as cluster head
    Assert.equal(contAddr.getNodeEntry(dummyAddr1).nodeType == DS.NodeType.ClusterHead, false, "Cluster head has issues");
    Assert.equal(contAddr.getNodeEntry(dummyAddr1).nodeType == DS.NodeType.MemberNode, false, "Cluster head has issues");
    contAddr.registerAsClusterHead(0, dummyAddr1);
    Assert.equal(contAddr.getNodeEntry(dummyAddr1).nodeType == DS.NodeType.ClusterHead, true, "Cluster head registration has issues");
    Assert.equal(contAddr.getNodeEntry(dummyAddr1).nodeType == DS.NodeType.MemberNode, false, "Cluster head registration has issues");
    // this should fail: contAddr.registerAsMemberNode(dummyAddr2, dummyAddr1);
  
    // Register dummyAddr2 node as member node of cluster with dummyAddr1 as cluster head
    Assert.equal(contAddr.getNodeEntry(dummyAddr2).nodeType == DS.NodeType.ClusterHead, false, "Node has issues");
    Assert.equal(contAddr.getNodeEntry(dummyAddr2).nodeType == DS.NodeType.MemberNode, false, "Node has issues");
    contAddr.registerAsMemberNode(dummyAddr1, dummyAddr2);
    Assert.equal(contAddr.getNodeEntry(dummyAddr2).nodeType == DS.NodeType.ClusterHead, false, "Member node registration has issues");
    Assert.equal(contAddr.getNodeEntry(dummyAddr2).nodeType == DS.NodeType.MemberNode, true, "Member node registration has issues");
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
