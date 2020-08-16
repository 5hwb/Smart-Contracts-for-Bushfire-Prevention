// SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

library IA {
    /**
     * @notice A struct for holding array and entry-to-index mappings
     */
    struct IndexedArray {
    // Array of entries
    uint256[] entries;
    // Number of entries in the IndexedArray
    uint numEntries;
    // Mapping from array entries -> array index
    mapping (uint256 => uint) entToIndex; 
  }

  /**
   * @notice Initialise the IndexedArray.
   * @param arr The IndexedArray to initialise
   */
  function initIndexedArray(IndexedArray storage arr) public {
    arr.entries.push(0); // Add a dummy value to represent null
    arr.numEntries = 1;
  }
  
  /**
   * @notice Get an element at the given index from an IndexedArray.
   * @param arr The IndexedArray to get the element from
   * @param idx The index of the entry to get
   * @return The element at the given index
   */
  function get(IndexedArray storage arr, uint256 idx) view public returns(uint256) {
    require(idx < arr.entries.length - 1);
    return arr.entries[idx+1];
  }
  
  /**
   * @notice Get an element with the given value from an IndexedArray.
   * @param arr The IndexedArray to get the element from
   * @param val The value of the entry to get
   * @return The element with the given value
   */
  function getWithVal(IndexedArray storage arr, uint256 val) view public returns(uint256) {
    return arr.entries[arr.entToIndex[val]];
  }
  
  /**
   * @notice Add an element to an IndexedArray.
   * @param arr The IndexedArray to add to
   * @param val The element to add
   */
  function add(IndexedArray storage arr, uint256 val) public {
    // Cancel the add if an existing entry with the same value is found
    if (getWithVal(arr, val) != 0) 
      return;
    
    // Add mapping of address to node array index 
    arr.entToIndex[val] = arr.numEntries;
    arr.entries.push(val);
    arr.numEntries++;
  }
  
  /**
   * @notice Check if an IndexedArray contains an element with the given value.
   * @param arr The IndexedArray to check
   * @param val The value of the entry to check
   * @return True if the element exists in the IndexedArray. False otherwise
   */
  function contains(IndexedArray storage arr, uint256 val) view public returns(bool) {
    return arr.entToIndex[val] != 0;
  }
  
  // function intersection(IndexedArray storage arr1, IndexedArray storage arr2) public returns(IndexedArray memory res) {
  // 
  // }

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
