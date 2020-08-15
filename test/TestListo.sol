// SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/Listo.sol";

contract TestListo {
  // The address of the contract to be tested
  Listo contAddr = Listo(DeployedAddresses.Listo());

  // Address of this contract
  address contractAddress = address(this);

  /***********************************************
   * TEST - something
   ***********************************************/

  DC.IndexedArray arr;

  function testSomething() public {
    contAddr.testThingo();

    DC.initIndexedArray(arr);
    DC.add(arr, 5);
    DC.add(arr, 3);
    DC.add(arr, 4);

    Assert.equal(DC.get(arr, 0), 5, "Retrieval error");
    Assert.equal(DC.get(arr, 1), 3, "Retrieval error");
    Assert.equal(DC.get(arr, 2), 4, "Retrieval error");
    
    Assert.equal(DC.contains(arr, 5), true, "It should be true1");
    Assert.equal(DC.contains(arr, 3), true, "It should be true2");
    Assert.equal(DC.contains(arr, 4), true, "It should be true3");
    Assert.equal(DC.contains(arr, 9), false, "It should be false");
  }
}
