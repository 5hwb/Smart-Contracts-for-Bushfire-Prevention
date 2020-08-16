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

  IA.IndexedArray arr;
  IA.IndexedArray arr2;
  uint[] res; 

  function testSomething() public {
    contAddr.testThingo();

    IA.initIndexedArray(arr);
    IA.add(arr, 5);
    IA.add(arr, 3);
    IA.add(arr, 4);
    IA.add(arr, 5);

    IA.initIndexedArray(arr2);
    IA.add(arr2, 4);
    IA.add(arr2, 8);
    IA.add(arr2, 3);
    
    Assert.equal(IA.get(arr, 0), 5, "Retrieval error");
    Assert.equal(IA.get(arr, 1), 3, "Retrieval error");
    Assert.equal(IA.get(arr, 2), 4, "Retrieval error");
    //Assert.equal(IA.get(arr, 3), 5, "SOMETHING IS RUGHT");
    
    Assert.equal(IA.getWithVal(arr, 5), 5, "Retrieval error");
    Assert.equal(IA.getWithVal(arr, 3), 3, "Retrieval error");
    Assert.equal(IA.getWithVal(arr, 4), 4, "Retrieval error");
    Assert.equal(IA.getWithVal(arr, 9), 0, "Retrieval error");
    
    Assert.equal(IA.contains(arr, 5), true, "It should be true1");
    Assert.equal(IA.contains(arr, 3), true, "It should be true2");
    Assert.equal(IA.contains(arr, 4), true, "It should be true3");
    Assert.equal(IA.contains(arr, 9), false, "It should be false");
    
    // Test the intersection() function
    // should get [3, 4]
    IA.intersection(arr, arr2.entries, res);

    Assert.equal(res[0], 3, "It should be 3");
    Assert.equal(res[1], 4, "It should be 4");
  }
}
