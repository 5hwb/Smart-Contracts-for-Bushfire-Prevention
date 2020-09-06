// SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "./DS.sol";
import "./QuickSort.sol";

// Dummy contract for testing the QuickSort library (since Truffle test won't work directly with library functions) 
contract QuickSortContract {
  function sort(DS.Node[] memory _data) public returns(DS.Node[] memory) {
    return QuickSort.sort(_data);
  }

  function sortInts(uint[] memory _data) public returns(uint[] memory) {
    return QuickSort.sortInts(_data);
  }

  function sortRev(uint[] memory _data) public returns(uint[] memory) {
    return QuickSort.sortRev(_data);
  }
}
