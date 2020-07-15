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
  NetworkFormation contract = NetworkFormation(DeployedAddresses.NetworkFormation());

  // Address of this contract
  address contractAddress = address(this);


  /***********************************************
   * TEST - Sorting
   ***********************************************/
   // Testing the getSortedNodes() function
   // note: address is just a placeholder
  function testSortNodes() public {
    address dummyAddr = 0xdcAD3A6D3569DF655070DEd06CB7A1b2CCd1D3a1;
    contract.addNode(1, dummyAddr, 89);
    contract.addNode(2, dummyAddr, 71);
    contract.addNode(3, dummyAddr, 53);
    contract.addNode(4, dummyAddr, 62);
    contract.addNode(5, dummyAddr, 90);
    contract.addNode(6, dummyAddr, 75);
    contract.addNode(7, dummyAddr, 62);
    contract.addNode(8, dummyAddr, 52);
    contract.addNode(9, dummyAddr, 95);
    contract.addNode(10, dummyAddr, 85);
    
    // sort to [95, 90, 89, 85, 75, 71, 62, 62, 53, 52]
    Structs.SensorNode[] memory sortedThingo = contract.getSortedNodes();
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
  function testGetNode() public {
    address dummyAddr1 = 0xaaAD3A6d3889dF677070DED06db7A1b2CCD1d3a1;
    address dummyAddr2 = 0xBbAD3a6D4489dfe77070DED06DB7a198CCD1D3A2;
    contract.addNode(100, dummyAddr1, 50);
    contract.addNode(101, dummyAddr2, 35);

    Structs.SensorNode memory node100 = contract.getNode(dummyAddr1);
    Assert.equal(node100.nodeID, 100, "Retrieval error");
    Assert.equal(node100.nodeAddress, dummyAddr1, "Retrieval error");
    Assert.equal(node100.energyLevel, 50, "Retrieval error");

    Structs.SensorNode memory node101 = contract.getNode(dummyAddr2);
    Assert.equal(node101.nodeID, 101, "Retrieval error");
    Assert.equal(node101.nodeAddress, dummyAddr2, "Retrieval error");
    Assert.equal(node101.energyLevel, 35, "Retrieval error");
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
