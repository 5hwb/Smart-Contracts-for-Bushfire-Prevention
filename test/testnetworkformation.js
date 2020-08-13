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

contract("NetworkFormation test cases", async accounts => {
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
    // Add the 'sink node'
    await instance.addNode(10, 111000, 100, [222001, 222002, 222003, 222004, 222005]);

    // Add neighbouring nodes
    await instance.addNode(11, 222001, 35, [111000, 222002]);
    await instance.addNode(12, 222002, 66, [111000, 222001, 222003]);
    await instance.addNode(13, 222003, 53, [111000, 222002, 222004]);
    await instance.addNode(14, 222004, 82, [111000, 222003, 222005]);
    await instance.addNode(15, 222005, 65, [111000, 222004]);
    
    // Get list of all SensorNode instances (just their addresses)
    let allNodes = await instance.getAllNodes.call();

    // Ensure the values within this SensorNode is as expected
    let firstNode = await SensorNode.at(allNodes[0]);    
    let firstNodeID = await firstNode.nodeID.call();
    let firstNodeAddr = await firstNode.nodeAddress.call();
    let firstNodeEnergyLevel = await firstNode.energyLevel.call();
    assert.equal(firstNodeID, 10);
    assert.equal(firstNodeAddr, 111000);
    assert.equal(firstNodeEnergyLevel, 100);
  });

  it("should send beacon", async () => {
    // Set sink node as the 1st cluster head
    await instance.registerAsClusterHead(0, 111000);

    // Set its network level to be 0 (because sink node!)
    let sinkNode = await SensorNode.at(await instance.getNode(111000));
    await sinkNode.setNetworkLevel(0);
    
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
    await instance.sendJoinRequests();
    let sinkNode = await SensorNode.at(await instance.getNode(111000));

    // Ensure the node addresses were added to list of join request nodes
    let joinRequestNodes = await sinkNode.getJoinRequestNodes.call();
    let node0 = await SensorNode.at(joinRequestNodes[0]);
    let node1 = await SensorNode.at(joinRequestNodes[1]);
    let node2 = await SensorNode.at(joinRequestNodes[2]);
    let node3 = await SensorNode.at(joinRequestNodes[3]);
    let node4 = await SensorNode.at(joinRequestNodes[4]);
    assert.equal(await node0.nodeAddress.call(), 222001);
    assert.equal(await node1.nodeAddress.call(), 222002);
    assert.equal(await node2.nodeAddress.call(), 222003);
    assert.equal(await node3.nodeAddress.call(), 222004);
    assert.equal(await node4.nodeAddress.call(), 222005);
  });

  it("should elect cluster heads", async () => {
    // 40% chance of being elected?
    await instance.electClusterHeads(111000, 40);

    // Get the prospective child nodes
    let node1 = await SensorNode.at(await instance.getNode(222001));
    let node2 = await SensorNode.at(await instance.getNode(222002));
    let node3 = await SensorNode.at(await instance.getNode(222003));
    let node4 = await SensorNode.at(await instance.getNode(222004));
    let node5 = await SensorNode.at(await instance.getNode(222005));
    
    assert.equal(await node1.isClusterHead.call(), false);
    assert.equal(await node2.isClusterHead.call(), true);
    assert.equal(await node3.isClusterHead.call(), false);
    assert.equal(await node4.isClusterHead.call(), true);
    assert.equal(await node5.isClusterHead.call(), false);
    
    assert.equal(await node1.isMemberNode.call(), true);
    assert.equal(await node2.isMemberNode.call(), false);
    assert.equal(await node3.isMemberNode.call(), true);
    assert.equal(await node4.isMemberNode.call(), false);
    assert.equal(await node5.isMemberNode.call(), true);
  });

  it("should send sensor readings to sink node", async () => {
    // Simulate reading values from each sensor node
    await instance.readSensorInput(9001, 222001);
    await instance.readSensorInput(9002, 222002);
    await instance.readSensorInput(9003, 222003);
    await instance.readSensorInput(9004, 222004);
    await instance.readSensorInput(9005, 222005);

    let node222001 = await SensorNode.at(await instance.getNode(222001));
    let node222002 = await SensorNode.at(await instance.getNode(222002));
    let node222003 = await SensorNode.at(await instance.getNode(222003));
    let node222004 = await SensorNode.at(await instance.getNode(222004));
    let node222005 = await SensorNode.at(await instance.getNode(222005));
    let node111000 = await SensorNode.at(await instance.getNode(111000));
    
    // Check that the sensor nodes got their readings
    assert.equal(await node222001.getSensorReadings.call(), 9001);
    assert.equal(await node222002.getSensorReadings.call(), 9002);
    assert.equal(await node222003.getSensorReadings.call(), 9003);
    assert.equal(await node222004.getSensorReadings.call(), 9004);
    assert.equal(await node222005.getSensorReadings.call(), 9005);

    // Check that the cluster head had received the sensor readings
    assert.equal((await node111000.getSensorReadings.call())[0], 9001);
    assert.equal((await node111000.getSensorReadings.call())[1], 9002);
    assert.equal((await node111000.getSensorReadings.call())[2], 9003);
    assert.equal((await node111000.getSensorReadings.call())[3], 9004);
    assert.equal((await node111000.getSensorReadings.call())[4], 9005);
  });
  
  /***********************************************
   * TEST - Sorting SensorNode instances
   ***********************************************/
  // it("should sort a SensorNode array", async () => {
  // 
  //   // sort to [89, 71, 62, 53]
  //   SensorNode[] memory sortedThingo = contAddr.getSortedNodes();
  //   // Check that nodes have been sorted by their energy levels in descending order
  //   Assert.equal(sortedThingo[0].energyLevel(), 89, "Sorting error");
  //   Assert.equal(sortedThingo[1].energyLevel(), 71, "Sorting error");
  //   Assert.equal(sortedThingo[2].energyLevel(), 62, "Sorting error");
  //   Assert.equal(sortedThingo[3].energyLevel(), 53, "Sorting error");
  //   // Another check to ensure the IDs are correct
  //   Assert.equal(sortedThingo[0].nodeID(), 3, "Sorting error - wrong ID");
  //   Assert.equal(sortedThingo[1].nodeID(), 4, "Sorting error - wrong ID");
  //   Assert.equal(sortedThingo[2].nodeID(), 2, "Sorting error - wrong ID");
  //   Assert.equal(sortedThingo[3].nodeID(), 1, "Sorting error - wrong ID");
  // });
  
  /***********************************************
   * TEST - Sorting integers
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
