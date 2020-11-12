# Bushfire Prevention Simulation

This is an Ethereum dapp that simulates a wireless sensor network architecture which aims to help prevent bushfires.

## Software used

Front-end:
* Node.js web app

Back-end:
* Ganache
* Node.js
* Truffle
* Ethereum blockchain

Text editor:
* Atom

## [Guide to setting up and running the dapp](SETUP.md)

## Directory information

* `contracts` - Ethereum smart contracts written in the Solidity language
* `migrations` - Migration scripts (run when migrating the compiled smart contracts onto the blockchain)
* `src` - Source code for Node.js web app GUI frontend
* `test` - Test cases for smart contracts written in Javascript and Solidity

## Note on smart contract naming

During much of the initial development phase, some of the smart contracts had very different names. They are shown in the table below.

| Current name | Old name |
|:---:|:---:|
| NodeEntries | NetworkFormation |
| NodeEntryLib | SensorNode |
| NodeRoleEntries | NetworkFormation2 |
| NodeRoleEntryLib | SensorNode2 |

## Tips

### Note on contract size

It cannot exceed 24KB in size!

### Difference between 'instance.myMethod()' and 'instance.myMethod.call()'

Truffle normally can auto-detect method calls as transactions (which modify the state and cost gas) or calls (which only reads the state and won't cost gas). To avoid gas costs, use the `.call()` method.

https://www.trufflesuite.com/docs/truffle/getting-started/interacting-with-your-contracts

### Number format of uint256 var in JavaScript

A 'BN' instance.

https://ethereum.stackexchange.com/questions/79349/what-is-words-in-uint256

## Preventing errors

### 'Error: ENOSPC: System limit for number of file watchers reached'

Temporary fix: `sudo sysctl fs.inotify.max_user_watches=524288 && sudo sysctl -p`

Don't make it permanent as it can lead to memory issues.

https://github.com/guard/listen/wiki/Increasing-the-amount-of-inotify-watchers#the-technical-details

### A node.js dependency refuses to install

```
npm ERR! code ENOLOCAL
npm ERR! Could not install from "node_modules/truffle-blockchain-utils/node_modules/web3/bignumber.js@git+https:/github.com/frozeman/bignumber.js-nolookahead.git#57692b3ecfc98bbdd6b3a516cb2353652ea49934" as it does not contain a package.json file.
```

Delete the `package-lock.json` file and run `npm install` again!

### Force update of smart contract

Delete the `build` folder before compiling.

## TODO

* [DONE] Rename 'NetworkFormation2' and 'SensorNode2' to something else that makes more sense. e.g. 'NodeRoleEntries' and 'NodeRoleEntry'.
* [SEE IF I CAN DO THIS] Idea: Each actuator behaves differently to the sensor readings - e.g. 1 would trigger at 37000 while another would trigger at 5000.
* [ONGOING] Clean up the code and add comments to make it more presentable.
* [TODO] Seriously consider using IPFS to store node information and readings.
* [DONE] Make network react to different stimuli: 
    - If sensor detects temp is > 37 degrees, alert controller, which in turn alerts the actuator and makes it trigger a device (sprinkler, alert fire services, etc).
    - If sensor temp is > 45 degrees, deactivate the sensor!
    - [DONE] Update test cases so that it shows that the actuator nodes got the message.
* [DONE] Add new flag to indicate if node is actuator, sensor, or controller. This can be done as an enum if possible.
    - Idea: sensor and actuator are leaf nodes (or cluster heads with no children). The remaining cluster heads are the controller nodes.
* [DONE] Implement the actual redundancy - when a node's cluster head fails, make that node connect to its backup cluster head.
* [DONE] Add test cases for newly added backup cluster heads (ensure the correct ones are being nominated)
* Refactor the code to allow for further expansion. Idea: split up NetworkFormation into several, smaller contracts.
* Make approval automatic.
