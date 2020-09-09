# Bushfire Prevention Simulation

This is an Ethereum dapp that simulates the proposed wireless sensor network architecture to help prevent bushfires.

## Note on contract size

It cannot exceed 24KB in size!

## Dependency

This project uses the OpenZeppelin Contracts library. Run this first:

`npm install @openzeppelin/contracts`

## TODO

* Make new contract for bushfire detecting operations and managing the node roles.
* [DONE] Implement the actual redundancy - when a node's cluster head fails, make that node connect to its backup cluster head.
* [DONE] Add test cases for newly added backup cluster heads (ensure the correct ones are being nominated)
* Refactor the code to allow for further expansion. Idea: split up NetworkFormation into several, smaller contracts.
* Make approval automatic.
