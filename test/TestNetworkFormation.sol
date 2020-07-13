// SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/NetworkFormation.sol";
import "../contracts/Structs.sol";

contract TestNetworkFormation {
  // TODO: next step - implement the cluster head election algorithm!

  // The address of the voting contract to be tested
  NetworkFormation networkFormation = NetworkFormation(DeployedAddresses.NetworkFormation());

  // Address of this contract
  address contractAddress = address(this);


  /***********************************************
   * TEST - Sorting
   ***********************************************/
   // Testing the getSortedNodes() function
   // note: address is just a placeholder
  function testSortNodes() public {
    address dummyAddr = 0xdcAD3A6D3569DF655070DEd06CB7A1b2CCd1D3a1;
    networkFormation.addNode(1, dummyAddr, 89);
    networkFormation.addNode(2, dummyAddr, 71);
    networkFormation.addNode(3, dummyAddr, 53);
    networkFormation.addNode(4, dummyAddr, 62);
    networkFormation.addNode(5, dummyAddr, 90);
    networkFormation.addNode(6, dummyAddr, 75);
    networkFormation.addNode(7, dummyAddr, 62);
    networkFormation.addNode(8, dummyAddr, 52);
    networkFormation.addNode(9, dummyAddr, 95);
    networkFormation.addNode(10, dummyAddr, 85);
    
    // sort to [95, 90, 89, 85, 75, 71, 62, 62, 53, 52]
    Structs.SensorNode[] memory sortedThingo = networkFormation.getSortedNodes();
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
    networkFormation.addNode(100, dummyAddr1, 50);
    networkFormation.addNode(101, dummyAddr2, 35);

    Structs.SensorNode memory node100 = networkFormation.getNode(dummyAddr1);
    Assert.equal(node100.nodeID, 100, "Retrieval error");
    Assert.equal(node100.nodeAddress, dummyAddr1, "Retrieval error");
    Assert.equal(node100.energyLevel, 50, "Retrieval error");

    Structs.SensorNode memory node101 = networkFormation.getNode(dummyAddr2);
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
  }
}
