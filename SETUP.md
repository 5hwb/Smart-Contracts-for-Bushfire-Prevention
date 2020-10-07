# Set up the Ethereum dapp

## Dependencies

* Ganache (one-click Ethereum test blockchain)
* Node.js
* Truffle (Node.js package)
* MetaMask (Firefox plugin to allow the Node.js app to communicate with the blockchain)

## Steps

1. Install Truffle as a global npm package: `sudo npm install -g --unsafe-perm=true --allow-root truffle`
2. Download the Ganache Ethereum client and create a new workspace.
3. Check `truffle-config.js` and ensure that the development **host** and **port** are set correctly. (for Ganache, host = '127.0.0.1' and port = '7545')

e.g.

```js
module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // for more about customizing your Truffle configuration!
  networks: {
    development: {
      host: "127.0.0.1",
      port: 7545,
      network_id: "*" // Match any network id
    },
    develop: {
      port: 8545
    }
  }
};
```

4. `truffle compile` - Compile the Solidity smart contract.
5. `truffle migrate` - Migrate the contract to blockchain.
    * If changes have been made since last deployment, delete the `build` folder and re-run `truffle migrate` again
6. `truffle test` - Run the smart contract test cases.
7. Install the MetaMask browser plugin in the browser - this will help the web app to interact with the blockchain.
8. Import the account by copying Ganache's 'mnemonic' (e.g. `compute base weird unknown main dignity license muffin evil cancel write same`) into the wallet seed field. Set a simple password (e.g. 'asdfnation').
    * In MetaMask, set the network to Ganache by creating a new network (if not created already) at http://127.0.0.1:7545
9. Check `bs-config.js`, the config for the 'lite-server' web server that will host the web app. It should look like this:

```js
{
  "server": {
    "baseDir": ["./src", "./build/contracts"]
  }
}
```

10. In `package.json`, put this in, so that when `npm run dev` is called, the lite-server will run:

```json
"scripts": {
  "dev": "lite-server",
  "test": "echo \"Error: no test specified\" && exit 1"
},
```

11. Run `npm install` to install all dependencies.
12. Run `npm run dev` to start the web app.
13. Optional - Install the Solidity compiler by running the following:

```
sudo add-apt-repository ppa:ethereum/ethereum
sudo apt-get update
sudo apt-get install solc
```

## Tips

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

## Force update of smart contract

Delete the `build` folder before compiling.
