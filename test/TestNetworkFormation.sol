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
   // Testing the getSortedNode() function
   function testSortNodes() public {
    networkFormation.addNode(1, 0xdCad3a6d3569DF655070DEd06cb7A1b2Ccd1D3AF, 89);
    networkFormation.addNode(2, 0xdCad3a6d3569DF655070DEd06cb7A1b2Ccd1D3AF, 71);
    networkFormation.addNode(3, 0xdCad3a6d3569DF655070DEd06cb7A1b2Ccd1D3AF, 53);
    networkFormation.addNode(4, 0xdCad3a6d3569DF655070DEd06cb7A1b2Ccd1D3AF, 62);
    
    // sort to [53, 62, 71, 89]
    Structs.SensorNode[] memory sortedThingo = networkFormation.getSortedNode();
    //console.log("sortedThingo = ");
    //console.log(sortedThingo);
    Assert.equal(sortedThingo[0].energyLevel, 53, "Sorting error");
    Assert.equal(sortedThingo[1].energyLevel, 62, "Sorting error");
    Assert.equal(sortedThingo[2].energyLevel, 71, "Sorting error");
    Assert.equal(sortedThingo[3].energyLevel, 89, "Sorting error");
  }

  
}
