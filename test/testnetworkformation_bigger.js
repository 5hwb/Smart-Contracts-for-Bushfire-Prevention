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

contract("NetworkFormation - 3-layer network test case", async accounts => {
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
    /*
    LAYOUT:
     _____   _____   _____   _____ 
    | 012 | | 013 | | 014 | | 015 |
    |__71_| |__83_| |__78_| |__80_|
     _____   _____   _____   _____ 
    | 006 | | 007 | | 008 | | 009 |
    |__79_| |__61_| |__94_| |__95_|
     _____   _____   _____   _____ 
    | 002 | | 003 | | 004 | | 010 |
    |__88_| |__82_| |__95_| |__86_|
     _____   _____   _____   _____ 
    | 001 | |  SN | | 005 | | 011 |
    |__82_| |_100_| |__87_| |__93_|
     */

    // Add the 'sink node'
    await instance.addNode(1, 111000, 100, [222001, 222002, 222003, 222004, 222005]);

    // Add neighbouring nodes
    // LAYER 1 NODES
    await instance.addNode(2, 222001, 82, [111000, 222002]);
    await instance.addNode(3, 222002, 88, [111000, 222006, 222007, 222003, 222001]);
    await instance.addNode(4, 222003, 82, [111000, 222006, 222007, 222008, 222002, 222003, 222004]);
    await instance.addNode(5, 222004, 95, [111000, 222007, 222008, 222009, 222010, 222011, 222005]);
    await instance.addNode(6, 222005, 87, [111000, 222003, 222004, 222010, 222011]);

    // LAYER 2 NODES
    await instance.addNode( 7, 222006, 79, [222012, 222013, 222007, 222002, 222003]);
    await instance.addNode( 8, 222007, 61, [222012, 222013, 222014, 222006, 222008, 222003, 222004]);
    await instance.addNode( 9, 222008, 94, [222013, 222014, 222015, 222007, 222009, 222003, 222010]);
    await instance.addNode(10, 222009, 95, [222014, 222015, 222008, 222004, 222010]);
    await instance.addNode(11, 222010, 86, [222008, 222009, 222004, 222005, 222011]);
    await instance.addNode(12, 222011, 93, [222004, 222010, 222005]);

    await instance.addNode(13, 222012, 71, [222013, 222006, 222007]);
    await instance.addNode(14, 222013, 83, [222012, 222014, 222006, 222008]);
    await instance.addNode(15, 222014, 78, [222013, 222015, 222008, 222009]);
    await instance.addNode(16, 222015, 80, [222014, 222008, 222009]);

    // Get list of all SensorNode instances (just their addresses)
    let allNodes = await instance.getAllNodes.call();

    // Ensure the values within this SensorNode is as expected
    let firstNode = await SensorNode.at(allNodes[0]);    
    let firstNodeID = await firstNode.nodeID.call();
    let firstNodeAddr = await firstNode.nodeAddress.call();
    let firstNodeEnergyLevel = await firstNode.energyLevel.call();
    assert.equal(firstNodeID, 1);
    assert.equal(firstNodeAddr, 111000);
    assert.equal(firstNodeEnergyLevel, 100);
  });
  // 
  // it("should send beacon", async () => {
  // 
  //   // Set sink node as the 1st cluster head
  //   await instance.registerAsClusterHead(0, 111000);
  // 
  //   // Set its network level to be 0 (because sink node!)
  //   let sinkNode = await SensorNode.at(await instance.getNode(111000));
  //   await sinkNode.setNetworkLevel(0);
  //   //console.log("parentNode = ");
  //   //console.log(await sinkNode.parentNode.call());
  // 
  //   // Send beacon from cluster head
  //   await instance.sendBeacon(111000);
  // 
  //   // Get the prospective child nodes
  //   let node1 = await SensorNode.at(await instance.getNode(222001));
  //   let node2 = await SensorNode.at(await instance.getNode(222002));
  //   let node3 = await SensorNode.at(await instance.getNode(222003));
  //   let node4 = await SensorNode.at(await instance.getNode(222004));
  //   let node5 = await SensorNode.at(await instance.getNode(222005));
  // 
  //   // Ensure network level is correct
  //   assert.equal(await node1.networkLevel.call(), 1);
  //   assert.equal(await node2.networkLevel.call(), 1);
  //   assert.equal(await node3.networkLevel.call(), 1);
  //   assert.equal(await node4.networkLevel.call(), 1);
  //   assert.equal(await node5.networkLevel.call(), 1);
  // });
  // 
  // it("should send join requests", async () => {
  //   // Make all nodes within range send a join request
  //   await instance.sendJoinRequests(111000);
  //   let sinkNode = await SensorNode.at(await instance.getNode(111000));
  //   /*let withinRangeNodes = await sinkNode.getWithinRangeNodes.call();
  //   for (var i = 0; i < withinRangeNodes.length; i++) {
  //     let nodeAddr = withinRangeNodes[i].words[0]; // need to convert it from a BN.js object to an integer
  //     let sNode = await SensorNode.at(await instance.getNode(nodeAddr));
  //     await instance.sendJoinRequest(nodeAddr, 111000);
  //   }*/
  // 
  //   // Ensure the node addresses were added to list of join request nodes
  //   let joinRequestNodes = await sinkNode.getJoinRequestNodes.call();
  //   let node0 = await SensorNode.at(joinRequestNodes[0]);
  //   let node1 = await SensorNode.at(joinRequestNodes[1]);
  //   let node2 = await SensorNode.at(joinRequestNodes[2]);
  //   let node3 = await SensorNode.at(joinRequestNodes[3]);
  //   let node4 = await SensorNode.at(joinRequestNodes[4]);
  //   assert.equal(await node0.nodeAddress.call(), 222001);
  //   assert.equal(await node1.nodeAddress.call(), 222002);
  //   assert.equal(await node2.nodeAddress.call(), 222003);
  //   assert.equal(await node3.nodeAddress.call(), 222004);
  //   assert.equal(await node4.nodeAddress.call(), 222005);
  // });
  // 
  // it("should elect cluster heads", async () => {
  //   // 40% chance of being elected?
  //   await instance.electClusterHeads(111000, 40);
  // 
  //   // Get the prospective child nodes
  //   let node1 = await SensorNode.at(await instance.getNode(222001));
  //   let node2 = await SensorNode.at(await instance.getNode(222002));
  //   let node3 = await SensorNode.at(await instance.getNode(222003));
  //   let node4 = await SensorNode.at(await instance.getNode(222004));
  //   let node5 = await SensorNode.at(await instance.getNode(222005));
  // 
  //   assert.equal(await node1.isClusterHead.call(), false);
  //   assert.equal(await node2.isClusterHead.call(), true);
  //   assert.equal(await node3.isClusterHead.call(), false);
  //   assert.equal(await node4.isClusterHead.call(), true);
  //   assert.equal(await node5.isClusterHead.call(), false);
  // 
  //   assert.equal(await node1.isMemberNode.call(), true);
  //   assert.equal(await node2.isMemberNode.call(), false);
  //   assert.equal(await node3.isMemberNode.call(), true);
  //   assert.equal(await node4.isMemberNode.call(), false);
  //   assert.equal(await node5.isMemberNode.call(), true);
  // });
  // 
  // it("should send sensor readings to sink node", async () => {
  //   // Simulate reading values from each sensor node
  //   await instance.readSensorInput([9001], 222001);
  //   await instance.readSensorInput([9002], 222002);
  //   await instance.readSensorInput([9003], 222003);
  //   await instance.readSensorInput([9004], 222004);
  //   await instance.readSensorInput([9005], 222005);
  // 
  //   let node222001 = await SensorNode.at(await instance.getNode(222001));
  //   let node222002 = await SensorNode.at(await instance.getNode(222002));
  //   let node222003 = await SensorNode.at(await instance.getNode(222003));
  //   let node222004 = await SensorNode.at(await instance.getNode(222004));
  //   let node222005 = await SensorNode.at(await instance.getNode(222005));
  //   let node111000 = await SensorNode.at(await instance.getNode(111000));
  // 
  //   // Check that the sensor nodes got their readings
  //   assert.equal(await node222001.getSensorReadings.call(), 9001);
  //   assert.equal(await node222002.getSensorReadings.call(), 9002);
  //   assert.equal(await node222003.getSensorReadings.call(), 9003);
  //   assert.equal(await node222004.getSensorReadings.call(), 9004);
  //   assert.equal(await node222005.getSensorReadings.call(), 9005);
  // 
  //   // Check that the cluster head had received the sensor readings
  //   assert.equal((await node111000.getSensorReadings.call())[0], 9001);
  //   assert.equal((await node111000.getSensorReadings.call())[1], 9002);
  //   assert.equal((await node111000.getSensorReadings.call())[2], 9003);
  //   assert.equal((await node111000.getSensorReadings.call())[3], 9004);
  //   assert.equal((await node111000.getSensorReadings.call())[4], 9005);
  // });
  
});
