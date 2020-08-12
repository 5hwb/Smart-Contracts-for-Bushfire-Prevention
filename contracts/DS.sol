// SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;

// DS = Data Structures.
library DS {
  // Struct that represents a sensor reading
  struct SensorReading {
    uint reading; // ID of the node
    bool exists;  // Check if the reading exists
  }
  
  // Struct that represents a beacon sent from cluster head
  struct Beacon {
    bool isSent;                // Check if the beacon is sent
    uint nextNetLevel;          // Next network level
    uint256 senderNodeAddr;     // Address of beacon-sending node
    uint256[] withinRangeNodes; // Addresses of nodes within range of the beacon-sending node
  }
}
