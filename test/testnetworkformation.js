// tutorials:
// * https://www.trufflesuite.com/docs/truffle/testing/writing-tests-in-javascript
// * https://kalis.me/assert-reverts-solidity-smart-contract-test-truffle/
// * https://ethereum.stackexchange.com/questions/48627/how-to-catch-revert-error-in-truffle-test-javascript#48629

const NetworkFormation = artifacts.require("NetworkFormation");
const QuickSort = artifacts.require("QuickSort");
const truffleAssert = require('truffle-assertions');

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
    
  });
  
  /***********************************************
   * TEST - Sorting
   ***********************************************/
  it("should sort an array", async () => {
    //let numCandidates = await instance.numCandidates();
    //assert.equal(numVoters.toNumber(), 0);
    let sortInstance = await QuickSort.deployed();
    let thingo = [9, 2, 73, 3, 6, 2, 29];
    // sort to [2, 2, 3, 6, 9, 29, 73]
    let sortedThingo = await sortInstance.sort.call(thingo);
    console.log("sortedThingo = ");
    console.log(sortedThingo);
    assert.equal(sortedThingo[0], 2);
    assert.equal(sortedThingo[1], 2);
    assert.equal(sortedThingo[2], 3);
    assert.equal(sortedThingo[3], 6);
    assert.equal(sortedThingo[4], 9);
    assert.equal(sortedThingo[5], 29);
    assert.equal(sortedThingo[6], 73);
  });
  

});
