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

  IA.IndexedArray ia;
  IA.IndexedArray ia2;
  uint[] res;
  
  // Test the get() and contains() IA functions
  function testGetAndContains() public {
    contAddr.testThingo();

    IA.initIndexedArray(ia);
    IA.add(ia, 5);
    IA.add(ia, 3);
    IA.add(ia, 4);
    IA.add(ia, 5); // this should do nothing
    IA.add(ia, 10);
    IA.add(ia, 8);
    IA.add(ia, 9);

    IA.initIndexedArray(ia2);
    IA.add(ia2, 4);
    IA.add(ia2, 8);
    IA.add(ia2, 3);
    IA.add(ia2, 11);
    IA.add(ia2, 7);
    IA.add(ia2, 10);
    
    Assert.equal(IA.get(ia, 0), 5, "Retrieval error");
    Assert.equal(IA.get(ia, 1), 3, "Retrieval error");
    Assert.equal(IA.get(ia, 2), 4, "Retrieval error");
    //Assert.equal(IA.get(ia, 3), 5, "SOMETHING IS RUGHT");
    
    Assert.equal(IA.getWithVal(ia, 5), 5, "Retrieval error");
    Assert.equal(IA.getWithVal(ia, 3), 3, "Retrieval error");
    Assert.equal(IA.getWithVal(ia, 4), 4, "Retrieval error");
    Assert.equal(IA.getWithVal(ia, 19), 0, "Retrieval error");
    
    Assert.equal(IA.contains(ia, 5), true, "It should be true1");
    Assert.equal(IA.contains(ia, 3), true, "It should be true2");
    Assert.equal(IA.contains(ia, 4), true, "It should be true3");
    Assert.equal(IA.contains(ia, 19), false, "It should be false");
    
    // Test the intersection() function
    // should get [3, 4, 10, 8]
    IA.intersection(ia, ia2.entries, res);

    Assert.equal(res[0], 4, "It should be 4");
    Assert.equal(res[1], 8, "It should be 8");
    Assert.equal(res[2], 3, "It should be 3");
    Assert.equal(res[3], 10, "It should be 10");
  }
  
  uint[] arr1;
  uint[] arr2;
  uint[] resa;
  
  // Test the inter() function with my WSN withinRangeNodes examples
  function testInter() public {
    arr1.push(0);
    arr1.push(5);
    arr1.push(3);
    arr1.push(4);
    arr1.push(10);
    arr1.push(8);
    arr1.push(9);
    
    arr2.push(0);
    arr2.push(4);
    arr2.push(8);
    arr2.push(3);
    arr2.push(11);
    arr2.push(7);
    arr2.push(10);

    IA.inter(arr1, arr2, resa);
    Assert.equal(resa[0], 3, "It should be 3");
    Assert.equal(resa[1], 4, "It should be 4");
    Assert.equal(resa[2], 10, "It should be 10");
    Assert.equal(resa[3], 8, "It should be 8");
    
  }
  
  uint[] arr02;
  uint[] arr02_clo;
  uint[] arr02_clo2;
  uint[] arr04;
  uint[] arr07;
  uint[] resb;
  uint[] resc;
  
  // Test the equals() function
  function testEquals() public {
    arr02.push(0);
    arr02.push(1);
    arr02.push(3);
    arr02.push(6);
    arr02.push(7);
    
    arr02_clo.push(0);
    arr02_clo.push(1);
    arr02_clo.push(3);
    arr02_clo.push(6);
    arr02_clo.push(7);

    arr02_clo2.push(0);
    arr02_clo2.push(1);
    arr02_clo2.push(8);
    arr02_clo2.push(6);
    arr02_clo2.push(7);

    arr04.push(0);
    arr04.push(3);
    arr04.push(5);
    arr04.push(7);
    arr04.push(8);
    arr04.push(9);
    arr04.push(10);
    arr04.push(11);

    Assert.equal(IA.equals(arr02, arr02_clo), true, "They should match");
    Assert.equal(IA.equals(arr02, arr02_clo2), false, "They should not match (not all elements equal)");
    Assert.equal(IA.equals(arr02, arr04), false, "They should not match (different lengths)");
  }
  
  // Test the inter() function with the WSN withinRangeNodes examples
  function testInter3Arrays() public {    
    arr07.push(0);
    arr07.push(2);
    arr07.push(3);
    arr07.push(4);
    arr07.push(6);
    arr07.push(8);
    arr07.push(12);
    arr07.push(13);
    arr07.push(14);

    IA.inter(arr02, arr04, resb);
    Assert.equal(resb[0], 3, "It should be 3");
    Assert.equal(resb[1], 7, "It should be 7");

    IA.inter(resb, arr07, resc);
    Assert.equal(resc[0], 3, "It should be 3");
    delete resb;
  }
  
  uint[] arr1245679; // [1,2,4,5,6,7,9]
  uint[] arr2345780; // [2,3,4,5,7,8,10]
  uint[] arr4679012; // [4,6,7,9,10,11,12]
  uint[] arr5789023; // [5,7,8,9,10,12,13]
  uint[] arrtemp1; // temp array to store the results
  uint[] arrtemp2; // need 2 temp storage arrays as Solidity won't let me do shit with memory arrays

  // Test the inter() function with four 7-element arrays whose total intersection is [7]. 
  function testInter4Arrays() public {
    arr1245679.push(0);
    arr1245679.push(1);
    arr1245679.push(2);
    arr1245679.push(4);
    arr1245679.push(5);
    arr1245679.push(6);
    arr1245679.push(7);
    arr1245679.push(9);

    arr2345780.push(0);
    arr2345780.push(2);
    arr2345780.push(3);
    arr2345780.push(4);
    arr2345780.push(5);
    arr2345780.push(7);
    arr2345780.push(8);
    arr2345780.push(10);

    arr4679012.push(0);
    arr4679012.push(4);
    arr4679012.push(6);
    arr4679012.push(7);
    arr4679012.push(9);
    arr4679012.push(10);
    arr4679012.push(11);
    arr4679012.push(12);

    arr5789023.push(0);
    arr5789023.push(5);
    arr5789023.push(7);
    arr5789023.push(8);
    arr5789023.push(9);
    arr5789023.push(10);
    arr5789023.push(12);
    arr5789023.push(13);

    // TODO implement this setup (as an iterative function) in SensorNode!
    delete arrtemp1;
    IA.inter(arr1245679, arr2345780, arrtemp1);
    Assert.equal(arrtemp1[0], 2, "It should be 2");
    Assert.equal(arrtemp1[1], 4, "It should be 4");
    Assert.equal(arrtemp1[2], 5, "It should be 5");
    Assert.equal(arrtemp1[3], 7, "It should be 7");
    
    delete arrtemp2;
    IA.inter(arrtemp1, arr4679012, arrtemp2);
    Assert.equal(arrtemp2[0], 4, "It should be 4");
    Assert.equal(arrtemp2[1], 7, "It should be 7");

    delete arrtemp1;
    IA.inter(arrtemp2, arr5789023, arrtemp1);
    Assert.equal(arrtemp1[0], 7, "It should be 7");    
  }
  
  event ShowHash(bytes32 hash);
  
  function testHash() public {
    bytes32 lel = keccak256("this.be.test");
    emit ShowHash(lel);
    Assert.equal(lel, bytes32(0x1481436747e1fe67659cee77ec8383b231e8f8eefe596007b4a51cea1b2c2ed8), "Hash is wrong. Or you forgot to update the expected hash");
  }
}
