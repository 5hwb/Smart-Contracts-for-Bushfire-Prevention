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
    arr.entries.push(0); // Add a dummy value to represent null
    arr.numEntries = 1;
  }
  
  function get(IndexedArray storage arr, uint256 idx) view public returns(uint256) {
    require(idx < arr.entries.length - 1);
    return arr.entries[idx+1];
  }
  
  function getWithVal(IndexedArray storage arr, uint256 val) view public returns(uint256) {
    return arr.entries[arr.entToIndex[val]];
  }
  
  function add(IndexedArray storage arr, uint256 val) public {
    // Cancel the add if an existing entry with the same value is found
    if (getWithVal(arr, val) != 0) 
      return;
    
    // Add mapping of address to node array index 
    arr.entToIndex[val] = arr.numEntries;
    arr.entries.push(val);
    arr.numEntries++;
  }
  
  function contains(IndexedArray storage arr, uint256 val) view public returns(bool) {
    return arr.entToIndex[val] != 0;
  }
  
  function intersection() public {
    
  }

}

contract Listo {
  // TODO: Use the IndexedArray to store withinRangeNodes
  // to make it easy to find their intersections.
  function testThingo() public {
    uint[5] memory aa02 = [uint(0), 1, 3, 6, 7];
    uint[8] memory aa04 = [uint(0), 3, 5, 7, 8, 9, 10, 11];
    uint[8] memory aa07 = [uint(2), 3, 4, 6, 8, 12, 13, 14];
  }
}
