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
  
  // DS.Links struct represents all parameters related to connections with other nodes in the WSN
  struct Links {
    uint256 parentNode;         // parent (cluster head) of this node
    uint256[] childNodes;       // children of this node (if cluster head)
    uint256[] joinRequestNodes; // nodes that have sent join requests to this node
    uint numOfJoinRequests;     // N_T
    uint256[] withinRangeNodes; // nodes that are within transmission distance to this node
  }
  
  enum NodeType { Unassigned, MemberNode, ClusterHead }
  enum NodeRole { Default, Sensor, Controller, Actuator }
  enum TriggerCondition { Default, LessThan, LessEqual, Equal, GreaterEqual, GreaterThan }

  // DS.Node struct represents the parameters associated with a single node in the WSN 
  struct Node {
    uint256 nodeAddress; // Address of the node
    // TODO eventually: Make the energy level based on the battery current and voltage available 
    uint energyLevel;    // give it when initialising.
    uint networkLevel;          // Tree level this node is located at
    NodeType nodeType;
    
    Links links;
    
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
        
    //RoleVariables rv;
  }

  // DS.Node struct represents the parameters associated with a single node in the WSN 
  struct NodeRoleStuff {
    uint256 nodeAddress; // Address of the node

    NodeRole nodeRole;
    
    // Indicate whether this node is triggering the execution of an external service
    bool isTriggeringExternalService;

    // The message to show when this node has triggered the external service
    string triggerMessage;
    
    uint triggerThreshold;
    //bool triggerCondition;
  }

}
