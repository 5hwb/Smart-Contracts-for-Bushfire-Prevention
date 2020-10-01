# Bushfire Prevention Simulation

This is an Ethereum dapp that simulates the proposed wireless sensor network architecture to help prevent bushfires.

## Note on contract size

It cannot exceed 24KB in size!

## Dependency

This project uses the OpenZeppelin Contracts library. Run this first:

`npm install @openzeppelin/contracts`

## TODO

* [SEE IF I CAN DO THIS] Idea: Each actuator behaves differently to the sensor readings - e.g. 1 would trigger at 37000 while another would trigger at 5000.
* [TODO] Seriously consider using IPFS to store node information and readings.
* [DONE] Make network react to different stimuli: 
    - If sensor detects temp is > 37 degrees, alert controller, which in turn alerts the actuator and makes it trigger a device (sprinkler, alert fire services, etc).
    - If sensor temp is > 45 degrees, deactivate the sensor!
    - [DONE] Update test cases so that it shows that the actuator nodes got the message.
* Make new contract for bushfire detecting operations and managing the node roles.
* [DONE] Add new flag to indicate if node is actuator, sensor, or controller. This can be done as an enum if possible.
    - Idea: sensor and actuator are leaf nodes (or cluster heads with no children). The remaining cluster heads are the controller nodes.
* [DONE] Implement the actual redundancy - when a node's cluster head fails, make that node connect to its backup cluster head.
* [DONE] Add test cases for newly added backup cluster heads (ensure the correct ones are being nominated)
* Refactor the code to allow for further expansion. Idea: split up NetworkFormation into several, smaller contracts.
* Make approval automatic.
