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
    networkFormation.addNode(1, 0xdcAD3A6D3569DF655070DEd06CB7A1b2CCd1D3a1, 89);
    networkFormation.addNode(2, 0xdcAD3A6D3569DF655070DEd06CB7A1b2CCd1D3a1, 71);
    networkFormation.addNode(3, 0xdcAD3A6D3569DF655070DEd06CB7A1b2CCd1D3a1, 53);
    networkFormation.addNode(4, 0xdcAD3A6D3569DF655070DEd06CB7A1b2CCd1D3a1, 62);
    networkFormation.addNode(5, 0xdcAD3A6D3569DF655070DEd06CB7A1b2CCd1D3a1, 90);
    networkFormation.addNode(6, 0xdcAD3A6D3569DF655070DEd06CB7A1b2CCd1D3a1, 75);
    networkFormation.addNode(7, 0xdcAD3A6D3569DF655070DEd06CB7A1b2CCd1D3a1, 62);
    networkFormation.addNode(8, 0xdcAD3A6D3569DF655070DEd06CB7A1b2CCd1D3a1, 52);
    networkFormation.addNode(9, 0xdcAD3A6D3569DF655070DEd06CB7A1b2CCd1D3a1, 95);
    networkFormation.addNode(10, 0xdcAD3A6D3569DF655070DEd06CB7A1b2CCd1D3a1, 85);
    
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
    address dummyAddr = 0xaaAD3A6d3889dF677070DED06db7A1b2CCD1d3a1;
    networkFormation.addNode(100, dummyAddr, 50);

    Structs.SensorNode memory node = networkFormation.getNode(dummyAddr);
    Assert.equal(node.nodeAddress, dummyAddr, "Retrieval error");
  }

  
}
