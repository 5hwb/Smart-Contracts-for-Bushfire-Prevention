// SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "./DS.sol";

library SensorNode2 {

  // Events
  event LogString(string str);

  /**
   * @notice Initialise the given node struct with the given values.
   * @param _daNodeRoleStuff The node to modify
   * @param _addr Node address
   */
  function initNodeStruct(DS.NodeRoleStuff storage _daNodeRoleStuff, uint256 _addr) public {
    _daNodeRoleStuff.nodeAddress = _addr;

  }
  
  /**
   * @notice Get a node from the given DS.NodeRoleStuff[] array and mapping with the given address.
   * @param _allNodes2 Array of node structs
   * @param _addrToNodeIndex2 Mapping from node address to array index
   * @param _nodeAddr The address of the node to get
   * @return The node with the given node address
   */
  function getNodeRoleStuff(DS.NodeRoleStuff[] storage _allNodes2, mapping(uint => uint) storage _addrToNodeIndex2, uint _nodeAddr) view public returns(DS.NodeRoleStuff storage) {
    uint nIdx = _addrToNodeIndex2[_nodeAddr];
    return _allNodes2[nIdx];
  }
  
  /**
   * @notice Set the given node's role as a Sensor.
   * @param _daNodeRoleStuff The node to set
   */
  function setAsSensorRole(DS.NodeRoleStuff storage _daNodeRoleStuff) public {
    _daNodeRoleStuff.nodeRole = DS.NodeRole.Sensor;
    _daNodeRoleStuff.triggerMessage = ""; // remove the actuator trigger message
  }
  
  /**
   * @notice Set the given node's role as a Controller.
   * @param _daNodeRoleStuff The node to set
   */
  function setAsControllerRole(DS.NodeRoleStuff storage _daNodeRoleStuff) public {
    _daNodeRoleStuff.nodeRole = DS.NodeRole.Controller;
    _daNodeRoleStuff.triggerMessage = ""; // remove the actuator trigger message
  }
  
  /**
   * @notice Set the given node's role as an Actuator.
   * @param _daNodeRoleStuff The node to set
   * @param _triggerMessage The message to show when the actuator is triggered
   */
  function setAsActuatorRole(DS.NodeRoleStuff storage _daNodeRoleStuff, string memory _triggerMessage) public {
    _daNodeRoleStuff.nodeRole = DS.NodeRole.Actuator;
    _daNodeRoleStuff.triggerMessage = _triggerMessage;
  }
}
