// SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

library DC {
  struct IndexedArray {
    uint256[] entries;
    uint numEntries;
    mapping (uint256 => uint) entToIndex; // array entries -> array index
  }

  function initIndexedArray(IndexedArray storage arr) public {
    arr.numEntries = 0;
  }
  
  function add(IndexedArray storage arr, uint256 val) public {
    // Add mapping of address to node array index 
    arr.entToIndex[val] = arr.numEntries;
    arr.entries.push(val);
    arr.numEntries++;
  }
  
  function get(IndexedArray storage arr, uint256 idx) view public returns(uint256) {
    return arr.entries[idx];
  }

}

contract Listo {
  function testThingo() public {
    uint[5] memory aa02 = [uint(0), 1, 3, 6, 7];
    uint[8] memory aa04 = [uint(0), 3, 5, 7, 8, 9, 10, 11];
    uint[8] memory aa07 = [uint(2), 3, 4, 6, 8, 12, 13, 14];
  }
}
