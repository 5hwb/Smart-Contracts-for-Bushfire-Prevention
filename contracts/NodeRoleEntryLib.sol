// SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "./DS.sol";

library NodeRoleEntryLib {

  // Events
  event LogString(string str);

  /**
   * @notice Initialise the given node struct with the given values.
   * @param _daEntry The node to modify
   * @param _addr Node address
   */
  function initNodeStruct(DS.NodeRoleEntry storage _daEntry, uint256 _addr) public {
    _daEntry.nodeAddress = _addr;

  }
  
  /**
   * @notice Get a node from the given DS.NodeRoleEntry[] array and mapping with the given address.
   * @param _allNodes2 Array of node structs
   * @param _addrToNodeIndex2 Mapping from node address to array index
   * @param _nodeAddr The address of the node to get
   * @return The node with the given node address
   */
  function getNodeRoleEntry(DS.NodeRoleEntry[] storage _allNodes2, mapping(uint => uint) storage _addrToNodeIndex2, uint _nodeAddr) view public returns(DS.NodeRoleEntry storage) {
    uint nIdx = _addrToNodeIndex2[_nodeAddr];
    return _allNodes2[nIdx];
  }
  
  /**
   * @notice Set the given node's role as a Sensor.
   * @param _daEntry The node to set
   */
  function setAsSensorRole(DS.NodeRoleEntry storage _daEntry) public {
    _daEntry.nodeRole = DS.NodeRole.Sensor;
    _daEntry.triggerMessage = ""; // remove the actuator trigger message
  }
  
  /**
   * @notice Set the given node's role as a Controller.
   * @param _daEntry The node to set
   */
  function setAsControllerRole(DS.NodeRoleEntry storage _daEntry) public {
    _daEntry.nodeRole = DS.NodeRole.Controller;
    _daEntry.triggerMessage = ""; // remove the actuator trigger message
  }
  
  /**
   * @notice Set the given node's role as an Actuator.
   * @param _daEntry The node to set
   * @param _triggerMessage The message to show when the actuator is triggered
   */
  function setAsActuatorRole(DS.NodeRoleEntry storage _daEntry, string memory _triggerMessage) public {
    _daEntry.nodeRole = DS.NodeRole.Actuator;
    _daEntry.triggerMessage = _triggerMessage;
  }

  /**
   * @notice Set the given node's triggered flag.
   * @param _daEntry The node to set
   * @param _isTriggeringExternalServise The desired flag status
   */
  function setTriggered(DS.NodeRoleEntry storage _daEntry, bool _isTriggeringExternalServise) public {
    _daEntry.isTriggeringExternalService = _isTriggeringExternalServise;
  }
}
