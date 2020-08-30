// SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "./DS.sol";

// From here: https://gist.github.com/subhodi/b3b86cc13ad2636420963e692a4d896f
library QuickSort {
  
  // Sort function for DS.Node arrays that sorts by energy level in descending order.
  // From here: https://gist.github.com/subhodi/b3b86cc13ad2636420963e692a4d896f
  function sort(DS.Node[] memory _data) public returns(DS.Node[] memory) {
    quickSort(_data, int(0), int(_data.length - 1));
    return _data;
  }
  
  function quickSort(DS.Node[] memory _arr, int _left, int _right) internal {
    int i = _left;
    int j = _right;
    if(i==j) return;
    uint pivot = _arr[uint(_left + (_right - _left) / 2)].energyLevel;
    while (i <= j) {
      while (_arr[uint(i)].energyLevel > pivot) i++;
      while (pivot > _arr[uint(j)].energyLevel) j--;
      if (i <= j) {
        DS.Node memory temp = _arr[uint(i)];
        _arr[uint(i)] = _arr[uint(j)];
        _arr[uint(j)] = temp;
        i++;
        j--;
      }
    }
    if (_left < j)
      quickSort(_arr, _left, j);
    if (i < _right)
      quickSort(_arr, i, _right);
  }

  
  // Quicksort function that sorts integer arrays in ascending order.
  function sortInts(uint[] memory data) public returns(uint[] memory) {
     quickSortInts(data, int(0), int(data.length - 1));
     return data;
  }
  
  function quickSortInts(uint[] memory arr, int left, int right) internal {
      int i = left;
      int j = right;
      if(i==j) return;
      uint pivot = arr[uint(left + (right - left) / 2)];
      while (i <= j) {
          while (arr[uint(i)] < pivot) i++;
          while (pivot < arr[uint(j)]) j--;
          if (i <= j) {
              (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
              i++;
              j--;
          }
      }
      if (left < j)
          quickSortInts(arr, left, j);
      if (i < right)
          quickSortInts(arr, i, right);
  }

  // Quicksort function that sorts integer arrays in descending order.
  function sortRev(uint[] memory data) public returns(uint[] memory) {
     quickSortRev(data, int(0), int(data.length - 1));
     return data;
  }
  
  function quickSortRev(uint[] memory arr, int left, int right) internal {
      int i = left;
      int j = right;
      if(i==j) return;
      uint pivot = arr[uint(left + (right - left) / 2)];
      while (i <= j) {
          while (arr[uint(i)] > pivot) i++;
          while (pivot > arr[uint(j)]) j--;
          if (i <= j) {
              (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
              i++;
              j--;
          }
      }
      if (left < j)
          quickSortRev(arr, left, j);
      if (i < right)
          quickSortRev(arr, i, right);
  }
}
