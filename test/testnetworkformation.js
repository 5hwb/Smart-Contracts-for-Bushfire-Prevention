// tutorials:
// * https://www.trufflesuite.com/docs/truffle/testing/writing-tests-in-javascript
// * https://kalis.me/assert-reverts-solidity-smart-contract-test-truffle/
// * https://ethereum.stackexchange.com/questions/48627/how-to-catch-revert-error-in-truffle-test-javascript#48629

// Contract abstractions provided by Truffle
// (web3.eth.Contract instances?)
const NetworkFormation = artifacts.require("NetworkFormation");
const QuickSort = artifacts.require("QuickSort");

// Required for some test cases
const truffleAssert = require('truffle-assertions');

const sensorNodeABI = [{"inputs":[{"internalType":"uint256","name":"_id","type":"uint256"},{"internalType":"uint256","name":"_addr","type":"uint256"},{"internalType":"uint256","name":"_energyLevel","type":"uint256"}],"stateMutability":"nonpayable","type":"constructor"},{"inputs":[{"internalType":"uint256","name":"addr","type":"uint256"}],"name":"addJoinRequestNode","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"addr","type":"uint256"}],"name":"addWithinRangeNode","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"childNodes","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"energyLevel","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getJoinRequestNodes","outputs":[{"internalType":"uint256[]","name":"","type":"uint256[]"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getWithinRangeNodes","outputs":[{"internalType":"uint256[]","name":"","type":"uint256[]"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"isClusterHead","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"isMemberNode","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"joinRequestNodes","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"networkLevel","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"nodeAddress","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"nodeID","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"numOfChildNodes","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"numOfJoinRequests","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"numOfOneHopClusterHeads","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"numOfWithinRangeNodes","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"parentNode","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"setAsClusterHead","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"setAsMemberNode","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"eLevel","type":"uint256"}],"name":"setEnergyLevel","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"nLevel","type":"uint256"}],"name":"setNetworkLevel","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"addr","type":"uint256"}],"name":"setParentNode","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"withinRangeNodes","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"}];

contract("NetworkFormation test", async accounts => {
  let instance;
  
  beforeEach(async () => {
    instance = await NetworkFormation.deployed();
  });

  /***********************************************
   * TEST - ADD NODES
   ***********************************************/
  it("should initialise everything correctly", async () => {
    //let numCandidates = await instance.numCandidates();
    //assert.equal(numVoters.toNumber(), 0);
    let numOfNodes = await instance.numOfNodes();
    assert.equal(numOfNodes, 0);
    let numOfLevels = await instance.numOfLevels();
    assert.equal(numOfLevels, 0);

    let allNodes = await instance.getAllNodes.call();
    console.log("allNodes = ");
    console.log(allNodes);
        
    let dummyAddr = [111001, 111002];
    await instance.addNode(1, 111000, 56, dummyAddr);
    allNodes = await instance.getAllNodes.call();
    console.log("allNodes = ");
    console.log(allNodes);

    let firstNode = new web3.eth.Contract(sensorNodeABI, allNodes[0]);    
    //console.log("firstNode = ");
    //console.log(firstNode);
    let firstNodeID = firstNode.methods.nodeID.call();
    let firstNodeAddr = firstNode.methods.nodeAddress.call();
    let firstNodeEnergyLevel = firstNode.methods.energyLevel.call();
    console.log(firstNodeID);
    console.log(firstNodeAddr);
    console.log(firstNodeEnergyLevel);
  });
  
  /***********************************************
   * TEST - Sorting
   ***********************************************/
  it("should sort an int array", async () => {
    //let numCandidates = await instance.numCandidates();
    //assert.equal(numVoters.toNumber(), 0);
    let sortInstance = await QuickSort.deployed();
    let thingo = [9, 2, 73, 3, 6, 2, 29];
    // sort to [2, 2, 3, 6, 9, 29, 73]
    let sortedThingo = await sortInstance.sort.call(thingo);
    //console.log("sortedThingo = ");
    //console.log(sortedThingo);
    assert.equal(sortedThingo[0], 2);
    assert.equal(sortedThingo[1], 2);
    assert.equal(sortedThingo[2], 3);
    assert.equal(sortedThingo[3], 6);
    assert.equal(sortedThingo[4], 9);
    assert.equal(sortedThingo[5], 29);
    assert.equal(sortedThingo[6], 73);
  });
  
  /***********************************************
   * TEST - Sorting backwards
   ***********************************************/
  it("should sort an int array backwards", async () => {
    //let numCandidates = await instance.numCandidates();
    //assert.equal(numVoters.toNumber(), 0);
    let sortInstance = await QuickSort.deployed();
    let thingo = [9, 2, 73, 3, 6, 2, 29];
    // sort to [73, 29, 9, 6, 3, 2, 2]
    let sortedThingo = await sortInstance.sortRev.call(thingo);
    //console.log("sortedThingo = ");
    //console.log(sortedThingo);
    assert.equal(sortedThingo[0], 73);
    assert.equal(sortedThingo[1], 29);
    assert.equal(sortedThingo[2], 9);
    assert.equal(sortedThingo[3], 6);
    assert.equal(sortedThingo[4], 3);
    assert.equal(sortedThingo[5], 2);
    assert.equal(sortedThingo[6], 2);
  });
  

});
