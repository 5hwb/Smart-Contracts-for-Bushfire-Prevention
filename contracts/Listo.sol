// SPDX-License-Identifier: MIT
//pragma solidity ^0.7.0;
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "./IA.sol";

contract Listo {
  // TODO: Use the IndexedArray to store withinRangeNodes
  // to make it easy to find their intersections.
  function testThingo() public {
    uint[5] memory aa02 = [uint(0), 1, 3, 6, 7];
    uint[8] memory aa04 = [uint(0), 3, 5, 7, 8, 9, 10, 11];
    uint[8] memory aa07 = [uint(2), 3, 4, 6, 8, 12, 13, 14];
  }
}
