// SPDX-License-Identifier: MIT
//pragma solidity ^0.7.0;
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
  
  /**
   * @notice Calculate the intersection between 2 arrays and output the results in a 3rd array.
   * @param ia1 The 1st IndexedArray to check
   * @param arr2 The 2nd array to check
   * @param res The array to put the results in
   */
  function intersection(IndexedArray storage ia1, uint256[] storage arr2, uint256[] storage res) public {
    
    for (uint j = 0; j < arr2.length; j++) {
      // Get non-zero elements in both arrays
      if (contains(ia1, arr2[j]) && arr2[j] != 0) {
        res.push(arr2[j]);
      }
    } 
  }
  
  /**
   * @notice Check if 2 arrays are equal.
   * @param arr1 The 1st array to check
   * @param arr2 The 2nd array to check
   * @return True if length of both arrays are identical and all elements match 
   */
  function equals(uint256[] storage arr1, uint256[] storage arr2) public returns(bool) {
    // If the lengths match...
    if (arr1.length == arr2.length) {
      bool isMatch = true;
      
      // and every element is a match...
      for (uint i = 0; i < arr1.length; i++) {
        isMatch = isMatch && (arr1[i] == arr2[i]);
      }
      
      return isMatch;
    }
    
    return false;
  }

  /**
   * @notice Copy 1 array to another. 
   * WARNING: arr2 must be 'deleted' before calling this function - otherwise there will be unexpected beaviour!
   * (fkn Solidity is a pain in the ass to work with)
   * @param arr1 The array to copy from
   * @param arr2 The array to place the contents of arr1
   */
  function copy(uint256[] storage arr1, uint256[] storage arr2) public {
    for (uint i = 0; i < arr1.length; i++) {
      arr2.push(arr1[i]);
    }
  }

  /**
   * @notice Calculate the intersection between 2 arrays and output the results in a 3rd array.
   * @param arr1 The 1st array to check
   * @param arr2 The 2nd array to check
   */
  function inter(uint256[] memory arr1, uint256[] memory arr2) public returns(uint256[] memory) {
    // Check which arr to use as the shortest array
    bool usingArr2 = (arr2.length < arr1.length);
    uint256[] memory shortArray = (usingArr2) ? arr2 : arr1;
    uint256[] memory longArray = (usingArr2) ? arr1 : arr2;
    
    // Result will be no longer than the length of the shortest array
    uint256[] memory result = new uint256[](shortArray.length);
    uint k = 0;
    
    for (uint i = 0; i < longArray.length; i++) {
      for (uint j = 0; j < shortArray.length; j++) {
        // Get non-zero elements in both arrays
        if (longArray[i] == shortArray[j] && longArray[i] != 0) {
          result[k] = longArray[i];
          k++;
        }
      }
    }
    
    return result;
  }
}
