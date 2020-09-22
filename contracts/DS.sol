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
  
  enum NodeType { Unassigned, MemberNode, ClusterHead }
  enum NodeRole { Default, Sensor, Controller, Actuator }

  struct ExtraVars {
    // Put extra variables here when the 'YulException: Stack too deep when compiling inline assembly' issue turns up.
    
    NodeRole nodeRole;
    
    // Indicate whether this node is triggering the execution of an external service
    bool isTriggeringExternalService;
    // The message to show when this node has triggered the external service
    string triggerMessage;
    
    // bool arrtemp1;
    // uint256 arrtemp2;    
    // uint256 arrtemp3;
    // ...
  }

  struct Node {
    uint nodeID;         // ID of the node
    uint256 nodeAddress; // Address of the node
    // TODO eventually: Make the energy level based on the battery current and voltage available 
    uint energyLevel;    // give it when initialising.
    uint networkLevel;          // Tree level this node is located at
    uint numOfOneHopClusterHeads; // init to 1
    // bool isClusterHead;           // init to false
    // bool isMemberNode;            // init to false
    NodeType nodeType;
    
    uint256 parentNode;         // (CHANGED FROM SensorNode) parent (cluster head) of this node
    uint256[] childNodes;       // (CHANGED FROM SensorNode) children of this node (if cluster head)
    uint256[] joinRequestNodes; // (CHANGED FROM SensorNode) nodes that have sent join requests to this node
    uint numOfJoinRequests;     // N_T
    uint256[] withinRangeNodes; // nodes that are within transmission distance to this node
    
    // Simulate receiving a beacon from a cluster head 
    DS.Beacon[] beacons;
    uint numOfBeacons;
    
    // Simulate the sensor reading process
    DS.SensorReading[] sensorReadings;    // Array of SensorReading structs
    uint numOfReadings; // Number of sensor readings held by this node

    // Backup nodes to communicate with if parent node (cluster head) fails
    uint256[] backupCHeads;
    
    // Indicate if node is active and ready to transfer data
    bool isActive;
        
    ExtraVars ev;
  }
}
