# Bushfire Prevention Simulation

This is an Ethereum dapp that simulates the proposed wireless ssensor network architecture to help prevent bushfires.

## Note on contract size

It cannot exceed 24KB in size!

## Dependency

This project uses the OpenZeppelin Contracts library. Run this first:

`npm install @openzeppelin/contracts`

## TODO

* Refactor the code to allow for further expansion. Idea: split up NetworkFormation into several, smaller contracts.
* Make new contract for managing the node roles and for bushfire detecting operations.
* Make approval automatic.
