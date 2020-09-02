# Bushfire Prevention Simulation

This is an Ethereum dapp that simulates the proposed wireless ssensor network architecture to help prevent bushfires.

## Note on contract size

It cannot exceed 24KB in size!

## Dependency

This project uses the OpenZeppelin Contracts library. Run this first:

`npm install @openzeppelin/contracts`

## TODO

* Implement the actual redundancy - when a node's cluster head fails, make that node connect to its backup cluster head.
  * Idea: cluster head carries a list of backup nodes that its child nodes can connect to if it fails. 
* [DONE] Add test cases for newly added backup cluster heads (ensure the correct ones are being nominated)
* Refactor the code to allow for further expansion. Idea: split up NetworkFormation into several, smaller contracts.
* Make new contract for managing the node roles and for bushfire detecting operations.
* Make approval automatic.
