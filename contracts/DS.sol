// SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;

// DS = Data Structures.
library DS {
  struct SensorReading {
    uint reading; // ID of the node
    bool exists;  // Check if the reading exists
  }
  
  struct Beacon {
    bool isSent;                // Check if the beacon is sent
    uint nextNetLevel;          // Next network level
    uint256 senderNodeAddr;      // The node that sent the beacon
    uint256[] withinRangeNodes; // Nodes within range of the node that sent the beacon
  }
}
