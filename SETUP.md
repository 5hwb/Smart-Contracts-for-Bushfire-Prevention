# Set up the Ethereum dapp

The dapp can be run on either Windows 10 or a Linux distribution such as Ubuntu and Linux Mint.

## Dependencies

* Ganache (one-click Ethereum test blockchain)
* Node.js
* Git (for fetching some of the Node.js packages)
* Truffle (Development environment for Ethereum, installed as a Node.js package)
* MetaMask (Firefox plugin to allow the Node.js app to communicate with the blockchain)

## Installation steps (Windows and Linux)

1. Install Node.js, Git and Ganache if not present on your system. Follow all default settings.
2. Install the MetaMask browser plugin in a web browser (either Chrome or Firefox) - this will help the web app to interact with the blockchain.
3. Open a terminal (Linux) or Command Prompt/Powershell (Windows) with administrator privileges.
    * In Windows, it is vital to run the Command Prompt with admin privileges as Truffle requires these to run on your system.
4. Install Truffle as a global npm package: `sudo npm install -g --unsafe-perm=true --allow-root truffle`
    * On Windows, leave out the 'sudo' and run this instead: `npm install -g --unsafe-perm=true --allow-root truffle`
5. Run `npm install` to install all dependencies.
    * If you get a `ENOENT: no such file or directory` error, delete the 'node_modules' folder and 'package-lock.json', then run `npm install` again. 
    * If the terminal freezes, press any key on the keyboard to get it to do something again.
6. Check 'truffle-config.js' and ensure that the development **host** and **port** are set correctly. (for Ganache, host = '127.0.0.1' and port = '7545')

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

7. Open Ganache and create a new workspace called 'Smart Contracts for Bushfire Prevention'. 
    * Click the 'Add Project' button and select 'truffle-config.js' in the source code direectory.
    * Afterwards, leave it running in the background.
8. In the terminal, run `truffle compile` to compile the Solidity smart contract. There should be no errors.
9. In the terminal, run `truffle migrate` to migrate the contract to the blockchain.
    * If changes have been made since last deployment, delete the `build` folder and re-run `truffle migrate` again.
10. In the terminal, run `truffle test` to run the smart contract test cases. (Make sure that Ganache is running, otherwise the tests will not run.)
11. Open the web browser where you installed MetaMask earlier. In MetaMask, click 'Import Wallet' and copy Ganache's 12-word 'mnemonic' (e.g. `compute base weird unknown main dignity license muffin evil cancel write same`) into the wallet seed field. Set a simple password (e.g. 'asdfnation').
12. In MetaMask, change the network from 'Main Ethereum Network' to Ganache by creating a new network.
    * Go to the MetaMask settings, then Networks.
    * Click 'Add Network', set the Network Name to 'Ganache' and the 'New RPC URL' to http://127.0.0.1:7545
13. Check `bs-config.js`, the config for the 'lite-server' web server that will host the web app. It should look like this:

```js
{
  "server": {
    "baseDir": ["./src", "./build/contracts"]
  }
}
```

14. In `package.json`, check to see if there is a "scripts" entry. If not present, put this in, so that when `npm run dev` is called, the lite-server will host the program:

```json
"scripts": {
  "dev": "lite-server",
  "test": "echo \"Error: no test specified\" && exit 1"
},
```

15. Run `npm run dev` to start the web app.
    * MetaMask will give a notification asking to connect the Ganache wallet with MetaMask. Follow the steps.
16. Optional - Install the Solidity compiler by running the following:

```
sudo add-apt-repository ppa:ethereum/ethereum
sudo apt-get update
sudo apt-get install solc
```

## How to run the dapp (Windows and Linux)

1. Copy the source code directory.
2. Open the Command Prompt with administrator privileges (Windows) or the terminal app (Linux).
3. Change the directory to the source code directory by running `cd C:\DIR\TO\SOURCE\CODE` where `C:\DIR\TO\SOURCE\CODE` is the source code directory.
4. Open Ganache and click the 'Smart Contracts for Bushfire Prevention' workspace.
5. Open Chrome.
6. Click the puzzle icon (extensions) and click MetaMask.
7. Close the loading icon. Set the network to 'Ganache' and sign in using the password 'asdfnation'
8. Run `npm run dev` in the Command Prompt.
9. After executing a piece of functionality (e.g. add node), refresh the page to get the latest results.
