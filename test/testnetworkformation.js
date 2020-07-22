// tutorials:
// * https://www.trufflesuite.com/docs/truffle/testing/writing-tests-in-javascript
// * https://kalis.me/assert-reverts-solidity-smart-contract-test-truffle/
// * https://ethereum.stackexchange.com/questions/48627/how-to-catch-revert-error-in-truffle-test-javascript#48629

// Contract abstractions provided by Truffle
// (TruffleContract instances)
const NetworkFormation = artifacts.require("NetworkFormation");
const SensorNode = artifacts.require("SensorNode");
const QuickSort = artifacts.require("QuickSort");

// Required for some test cases
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
    let numOfNodes = await instance.numOfNodes();
    assert.equal(numOfNodes, 0);
    let numOfLevels = await instance.numOfLevels();
    assert.equal(numOfLevels, 0);

  });
  
  it("should add SensorNode instances", async () => {
    // Add a SensorNode
    let dummyAddr = [1001, 1002];
    await instance.addNode(1, 1000, 56, dummyAddr);

    // Get list of all SensorNode instances (just their addresses)
    let allNodes = await instance.getAllNodes.call();

    // Ensure the values within this SensorNode is as expected
    let firstNode = await SensorNode.at(allNodes[0]);    
    //console.log("firstNode = ");
    //console.log(firstNode);
    let firstNodeID = await firstNode.nodeID.call();
    let firstNodeAddr = await firstNode.nodeAddress.call();
    let firstNodeEnergyLevel = await firstNode.energyLevel.call();
    assert.equal(firstNodeID, 1);
    assert.equal(firstNodeAddr, 1000);
    assert.equal(firstNodeEnergyLevel, 56);
  });

  it("should send beacon", async () => {
    // Add the 'sink node'
    await instance.addNode(10, 111000, 100, [222001, 222002, 222003, 222004, 222005]);

    // Add neighbouring nodes
    await instance.addNode(11, 222001, 35, [111000, 222002]);
    await instance.addNode(12, 222002, 66, [111000, 222001, 222003]);
    await instance.addNode(13, 222003, 53, [111000, 222002, 222004]);
    await instance.addNode(14, 222004, 82, [111000, 222003, 222005]);
    await instance.addNode(15, 222005, 65, [111000, 222004]);
    
    // Set sink node as the 1st cluster head
    await instance.registerAsClusterHead(111000);

    // Set its network level to be 0 (because sink node!)
    let sinkNode = await SensorNode.at(await instance.getNode(111000));
    await sinkNode.setNetworkLevel(0);
    //console.log(await sinkNode.networkLevel.call());
    
    // Send beacon from cluster head
    await instance.sendBeacon(111000);

    // Get the prospective child nodes
    let node1 = await SensorNode.at(await instance.getNode(222001));
    let node2 = await SensorNode.at(await instance.getNode(222002));
    let node3 = await SensorNode.at(await instance.getNode(222003));
    let node4 = await SensorNode.at(await instance.getNode(222004));
    let node5 = await SensorNode.at(await instance.getNode(222005));
    
    // Ensure network level is correct
    assert.equal(await node1.networkLevel.call(), 1);
    assert.equal(await node2.networkLevel.call(), 1);
    assert.equal(await node3.networkLevel.call(), 1);
    assert.equal(await node4.networkLevel.call(), 1);
    assert.equal(await node5.networkLevel.call(), 1);
  });

  it("should send join requests", async () => {
    // Make all nodes within range send a join request
    let sinkNode = await SensorNode.at(await instance.getNode(111000));
    let withinRangeNodes = await sinkNode.getWithinRangeNodes.call();
    for (var i = 0; i < withinRangeNodes.length; i++) {
      let nodeAddr = withinRangeNodes[i].words[0]; // need to convert it from a BN.js object to an integer
      let sNode = await SensorNode.at(await instance.getNode(nodeAddr));
      await instance.sendJoinRequest(nodeAddr, 111000);
    }

    // Ensure the node addresses were added to list of join request nodes
    let joinRequestNodes = await sinkNode.getJoinRequestNodes.call();
    assert.equal(joinRequestNodes[0].words[0], 222001);
    assert.equal(joinRequestNodes[1].words[0], 222002);
    assert.equal(joinRequestNodes[2].words[0], 222003);
    assert.equal(joinRequestNodes[3].words[0], 222004);
    assert.equal(joinRequestNodes[4].words[0], 222005);
  });

  it("should elect cluster heads", async () => {
    await instance.electClusterHeads(111000);

    // Get the prospective child nodes
    let node1 = await SensorNode.at(await instance.getNode(222001));
    let node2 = await SensorNode.at(await instance.getNode(222002));
    let node3 = await SensorNode.at(await instance.getNode(222003));
    let node4 = await SensorNode.at(await instance.getNode(222004));
    let node5 = await SensorNode.at(await instance.getNode(222005));
    
    // TODO: find out if sort is actually working?
    console.log("isClusterHead:");
    console.log(await node1.isClusterHead.call());
    console.log(await node2.isClusterHead.call());
    console.log(await node3.isClusterHead.call());
    console.log(await node4.isClusterHead.call());
    console.log(await node5.isClusterHead.call());
    console.log("isMemberNode:");
    console.log(await node1.isMemberNode.call());
    console.log(await node2.isMemberNode.call());
    console.log(await node3.isMemberNode.call());
    console.log(await node4.isMemberNode.call());
    console.log(await node5.isMemberNode.call());
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
  

  it("this be dummy test", async () => {
    assert.equal(true, 1);
  });

});
