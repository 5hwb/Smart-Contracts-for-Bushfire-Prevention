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
    LAYOUT (Mxx = member node num xx, Cxx = cluster head num xx):
    _______   _______   _______   _______
    | M12 |   | M13 |   | M14 |   | M15 |
    |__71_|   |__83_|   |__78_|   |__80_|
       |     /             |         |
       |    /              |         |
    ___|___/  _______   ___|___   ___|___
    | C06 |   | M07 |   | C08 |   | C09 |
    |__79_|   |__61_|   |__94_|   |__95_|
       |     /             |     /
       |    /              |    /
    ___|___/  _______   ___|___/  _______
    | C02 |   | M03 |   | C04 |___| M10 |
    |__88_|   |__82_|   |__95_|   |__86_|
           \     |     /       \
            \    |    /         \
    _______  \___|___/  _______  \_______
    | M01 |___|  SN |___| M05 |   | M11 |
    |__82_|   |_100_|   |__87_|   |__93_|
     */

    // Add the 'sink node'
    await instance.addNode(1, 111000, 100, [222001, 222002, 222003, 222004, 222005]);

    // Add neighbouring nodes
    // LAYER 1 NODES
    await instance.addNode(2, 222001, 82, [111000, 222002, 222003]);
    await instance.addNode(3, 222002, 88, [111000, 222006, 222007, 222003, 222001]);
    await instance.addNode(4, 222003, 82, [111000, 222006, 222007, 222008, 222002, 222004, 222001, 222005]);
    await instance.addNode(5, 222004, 95, [111000, 222007, 222008, 222009, 222003, 222010, 222005, 222011]);
    await instance.addNode(6, 222005, 87, [111000, 222003, 222004, 222010, 222011]);

    // LAYER 2 NODES
    await instance.addNode( 7, 222006, 79, [222012, 222013, 222007, 222002, 222003]);
    await instance.addNode( 8, 222007, 61, [222012, 222013, 222014, 222006, 222008, 222002, 222003, 222004]);
    await instance.addNode( 9, 222008, 94, [222013, 222014, 222015, 222007, 222009, 222003, 222004, 222010]);
    await instance.addNode(10, 222009, 95, [222014, 222015, 222008, 222004, 222010]);
    await instance.addNode(11, 222010, 86, [222008, 222009, 222004, 222005, 222011]);
    await instance.addNode(12, 222011, 93, [222004, 222010, 222005]);

    // LAYER 3 NODES
    await instance.addNode(13, 222012, 71, [222013, 222006, 222007]);
    await instance.addNode(14, 222013, 83, [222012, 222014, 222006, 222007, 222008]);
    await instance.addNode(15, 222014, 78, [222013, 222015, 222007, 222008, 222009]);
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

  it("should send beacon for Layer 1 nodes", async () => {
    
    // Set sink node as the 1st cluster head
    await instance.registerAsClusterHead(0, 111000);

    // Set its network level to be 0 (because sink node!)
    let sinkNode = await SensorNode.at(await instance.getNode(111000));
    await sinkNode.setNetworkLevel(0);
    //console.log("parentNode = ");
    //console.log(await sinkNode.parentNode.call());
    
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

  it("should send join requests for Layer 1 nodes", async () => {
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

  it("should elect cluster heads for Layer 1 nodes", async () => {
    // 50% chance of cluster head being elected
    await instance.electClusterHeads(111000, 50);

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

  it("should send beacon for Layer 2 nodes", async () => {
    // Send beacon from Level 1 cluster heads (do this manually for now.)
    await instance.sendBeacon(222002);
    await instance.sendBeacon(222004);

    // Get the currently elected cluster heads
    let nodeSN = await SensorNode.at(await instance.getNode(111000));
    let nodeCH1 = await SensorNode.at(await instance.getNode(222002));
    let nodeCH2 = await SensorNode.at(await instance.getNode(222004));
    
    // Get the prospective child nodes
    let node06 = await SensorNode.at(await instance.getNode(222006));
    let node07 = await SensorNode.at(await instance.getNode(222007));
    let node08 = await SensorNode.at(await instance.getNode(222008));
    let node09 = await SensorNode.at(await instance.getNode(222009));
    let node10 = await SensorNode.at(await instance.getNode(222010));
    let node11 = await SensorNode.at(await instance.getNode(222011));
    
    // Ensure network level is correct
    assert.equal(await nodeSN.networkLevel.call(), 0);
    assert.equal(await nodeCH1.networkLevel.call(), 1);
    assert.equal(await nodeCH2.networkLevel.call(), 1);
    assert.equal(await node06.networkLevel.call(), 2);
    assert.equal(await node07.networkLevel.call(), 2);
    assert.equal(await node08.networkLevel.call(), 2);
    assert.equal(await node09.networkLevel.call(), 2);
    assert.equal(await node10.networkLevel.call(), 2);
    assert.equal(await node11.networkLevel.call(), 2);

    var node06NumBeacons = await node06.numOfBeacons.call();
    for (var i = 0; i < node06NumBeacons; i++) {
      let node06BeaconData = await node06.getBeaconAt.call(i);
      console.log("node06BeaconData = "); console.log(node06BeaconData);
    }
    var node07NumBeacons = await node07.numOfBeacons.call();
    for (var i = 0; i < node07NumBeacons; i++) {
      let node07BeaconData = await node07.getBeaconAt.call(i);
      console.log("node07BeaconData = "); console.log(node07BeaconData);
    }
    var node08NumBeacons = await node08.numOfBeacons.call();
    for (var i = 0; i < node08NumBeacons; i++) {
      let node08BeaconData = await node08.getBeaconAt.call(i);
      console.log("node08BeaconData = "); console.log(node08BeaconData);
    }
    var node09NumBeacons = await node09.numOfBeacons.call();
    for (var i = 0; i < node09NumBeacons; i++) {
      let node09BeaconData = await node09.getBeaconAt.call(i);
      console.log("node09BeaconData = "); console.log(node09BeaconData);
    }
    var node10NumBeacons = await node10.numOfBeacons.call();
    for (var i = 0; i < node10NumBeacons; i++) {
      let node10BeaconData = await node10.getBeaconAt.call(i);
      console.log("node10BeaconData = "); console.log(node10BeaconData);
    }
    var node11NumBeacons = await node11.numOfBeacons.call();
    for (var i = 0; i < node11NumBeacons; i++) {
      let node11BeaconData = await node11.getBeaconAt.call(i);
      console.log("node11BeaconData = "); console.log(node11BeaconData);
    }
    
  });

  it("should send join requests for Layer 2 nodes", async () => {
    // Make all nodes within range send a join request
    await instance.sendJoinRequests();
    let cHead1 = await SensorNode.at(await instance.getNode(222002));
    let cHead2 = await SensorNode.at(await instance.getNode(222004));
  
    // Ensure the node addresses were added to list of join request nodes
    let cHead1joinRequestNodes = await cHead1.getJoinRequestNodes.call();
    let node1_0 = await SensorNode.at(cHead1joinRequestNodes[0]);
    let node1_1 = await SensorNode.at(cHead1joinRequestNodes[1]);
    let cHead2joinRequestNodes = await cHead2.getJoinRequestNodes.call();
    let node2_0 = await SensorNode.at(cHead2joinRequestNodes[0]);
    let node2_1 = await SensorNode.at(cHead2joinRequestNodes[1]);
    let node2_2 = await SensorNode.at(cHead2joinRequestNodes[2]);
    let node2_3 = await SensorNode.at(cHead2joinRequestNodes[3]);
    assert.equal(await node1_0.nodeAddress.call(), 222006);
    assert.equal(await node1_1.nodeAddress.call(), 222007);
  
    assert.equal(await node2_0.nodeAddress.call(), 222008);
    assert.equal(await node2_1.nodeAddress.call(), 222009);
    assert.equal(await node2_2.nodeAddress.call(), 222010);
    assert.equal(await node2_3.nodeAddress.call(), 222011);
  });

  it("should elect cluster heads for Layer 2 nodes", async () => {
    // 50% chance of cluster head being elected
    await instance.electClusterHeads(222002, 50);
    await instance.electClusterHeads(222004, 50);
  
    // Get the prospective child nodes
    let node2_06 = await SensorNode.at(await instance.getNode(222006));
    let node2_07 = await SensorNode.at(await instance.getNode(222007));    
    let node4_08 = await SensorNode.at(await instance.getNode(222008));
    let node4_09 = await SensorNode.at(await instance.getNode(222009));
    let node4_10 = await SensorNode.at(await instance.getNode(222010));
    let node4_11 = await SensorNode.at(await instance.getNode(222011));
  
    assert.equal(await node2_06.isClusterHead.call(), true);
    assert.equal(await node2_07.isClusterHead.call(), false);
    assert.equal(await node4_08.isClusterHead.call(), true);
    assert.equal(await node4_09.isClusterHead.call(), true);
    assert.equal(await node4_10.isClusterHead.call(), false);
    assert.equal(await node4_11.isClusterHead.call(), false);
  
    assert.equal(await node2_06.isMemberNode.call(), false);
    assert.equal(await node2_07.isMemberNode.call(), true);
    assert.equal(await node4_08.isMemberNode.call(), false);
    assert.equal(await node4_09.isMemberNode.call(), false);
    assert.equal(await node4_10.isMemberNode.call(), true);
    assert.equal(await node4_11.isMemberNode.call(), true);
  });

  it("should send beacon for Layer 3 nodes", async () => {
    // Send beacon from Level 2 cluster heads (do this manually for now.)
    await instance.sendBeacon(222006);
    await instance.sendBeacon(222008);
    await instance.sendBeacon(222009);

    // Get the currently elected cluster heads
    let nodeSN = await SensorNode.at(await instance.getNode(111000));
    let nodeCHL1_1 = await SensorNode.at(await instance.getNode(222002));
    let nodeCHL1_2 = await SensorNode.at(await instance.getNode(222004));
    let nodeCHL2_1 = await SensorNode.at(await instance.getNode(222006));
    let nodeCHL2_2 = await SensorNode.at(await instance.getNode(222008));
    let nodeCHL2_3 = await SensorNode.at(await instance.getNode(222009));

    // Get the prospective child nodes
    let node12 = await SensorNode.at(await instance.getNode(222012));
    let node13 = await SensorNode.at(await instance.getNode(222013));
    let node14 = await SensorNode.at(await instance.getNode(222014));
    let node15 = await SensorNode.at(await instance.getNode(222015));
    
    // Ensure network level is correct
    assert.equal(await nodeSN.networkLevel.call(), 0);
    assert.equal(await nodeCHL1_1.networkLevel.call(), 1);
    assert.equal(await nodeCHL1_2.networkLevel.call(), 1);
    assert.equal(await nodeCHL2_1.networkLevel.call(), 2);
    assert.equal(await nodeCHL2_2.networkLevel.call(), 2);
    assert.equal(await nodeCHL2_3.networkLevel.call(), 2);
    assert.equal(await node12.networkLevel.call(), 3);
    assert.equal(await node13.networkLevel.call(), 3);
    assert.equal(await node14.networkLevel.call(), 3);
    assert.equal(await node15.networkLevel.call(), 3);
  });

  it("should send join requests for Layer 3 nodes", async () => {
    // Make all nodes within range send a join request
    await instance.sendJoinRequests();
    let cHead1 = await SensorNode.at(await instance.getNode(222006));
    let cHead2 = await SensorNode.at(await instance.getNode(222008));
    let cHead3 = await SensorNode.at(await instance.getNode(222009)); // this one has no nodes to rule over as 222008 has taken the last one
  
    // Ensure the node addresses were added to list of join request nodes
    let cHead1joinRequestNodes = await cHead1.getJoinRequestNodes.call();
    let node1_0 = await SensorNode.at(cHead1joinRequestNodes[0]);
    let node1_1 = await SensorNode.at(cHead1joinRequestNodes[1]);
    assert.equal(await node1_0.nodeAddress.call(), 222012);
    assert.equal(await node1_1.nodeAddress.call(), 222013);

    let cHead2joinRequestNodes = await cHead2.getJoinRequestNodes.call();
    let node2_0 = await SensorNode.at(cHead2joinRequestNodes[0]);
    let node2_1 = await SensorNode.at(cHead2joinRequestNodes[1]);
    assert.equal(await node2_0.nodeAddress.call(), 222014);
    assert.equal(await node2_1.nodeAddress.call(), 222015);
  });

  it("should elect cluster heads for Layer 3 nodes", async () => {
    // 50% chance of cluster head being elected
    await instance.electClusterHeads(222006, 50);
    await instance.electClusterHeads(222008, 50);
    await instance.electClusterHeads(222009, 50);
  
    // Get the prospective child nodes
    let node6_12 = await SensorNode.at(await instance.getNode(222012));
    let node6_13 = await SensorNode.at(await instance.getNode(222013));    
    let node8_14 = await SensorNode.at(await instance.getNode(222014));
    let node8_15 = await SensorNode.at(await instance.getNode(222015));
  
    assert.equal(await node6_12.isClusterHead.call(), false);
    assert.equal(await node6_13.isClusterHead.call(), true);
    assert.equal(await node8_14.isClusterHead.call(), false);
    assert.equal(await node8_15.isClusterHead.call(), true);
  
    assert.equal(await node6_12.isMemberNode.call(), true);
    assert.equal(await node6_13.isMemberNode.call(), false);
    assert.equal(await node8_14.isMemberNode.call(), true);
    assert.equal(await node8_15.isMemberNode.call(), false);
  });

  it("should send sensor readings to sink node", async () => {
    // Simulate reading values from each sensor node
    await instance.readSensorInput(9001, 222001);
    await instance.readSensorInput(9002, 222002);
    await instance.readSensorInput(9003, 222003);
    await instance.readSensorInput(9004, 222004);
    await instance.readSensorInput(9005, 222005);
    await instance.readSensorInput(9006, 222006);
    await instance.readSensorInput(9007, 222007);
    await instance.readSensorInput(9008, 222008);
    await instance.readSensorInput(9009, 222009);
    await instance.readSensorInput(9010, 222010);
    await instance.readSensorInput(9011, 222011);
    await instance.readSensorInput(9012, 222012);
    await instance.readSensorInput(9013, 222013);
    await instance.readSensorInput(9014, 222014);
    await instance.readSensorInput(9015, 222015);

    let node111000 = await SensorNode.at(await instance.getNode(111000));
    let node222001 = await SensorNode.at(await instance.getNode(222001));
    let node222002 = await SensorNode.at(await instance.getNode(222002));
    let node222003 = await SensorNode.at(await instance.getNode(222003));
    let node222004 = await SensorNode.at(await instance.getNode(222004));
    let node222005 = await SensorNode.at(await instance.getNode(222005));
    let node222006 = await SensorNode.at(await instance.getNode(222006));
    let node222007 = await SensorNode.at(await instance.getNode(222007));
    let node222008 = await SensorNode.at(await instance.getNode(222008));
    let node222009 = await SensorNode.at(await instance.getNode(222009));
    let node222010 = await SensorNode.at(await instance.getNode(222010));
    let node222011 = await SensorNode.at(await instance.getNode(222011));
    let node222012 = await SensorNode.at(await instance.getNode(222012));
    let node222013 = await SensorNode.at(await instance.getNode(222013));
    let node222014 = await SensorNode.at(await instance.getNode(222014));
    let node222015 = await SensorNode.at(await instance.getNode(222015));
    
    // Check that all sensor nodes got their readings
    assert.equal((await node222001.getSensorReadings.call())[0], 9001);
    assert.equal((await node222003.getSensorReadings.call())[0], 9003);
    assert.equal((await node222005.getSensorReadings.call())[0], 9005);
    assert.equal((await node222007.getSensorReadings.call())[0], 9007);
    assert.equal((await node222009.getSensorReadings.call())[0], 9009);
    assert.equal((await node222010.getSensorReadings.call())[0], 9010);
    assert.equal((await node222011.getSensorReadings.call())[0], 9011);
    assert.equal((await node222012.getSensorReadings.call())[0], 9012);
    assert.equal((await node222013.getSensorReadings.call())[0], 9013);
    assert.equal((await node222014.getSensorReadings.call())[0], 9014);
    assert.equal((await node222015.getSensorReadings.call())[0], 9015);

    // Check that the Layer 2 cluster heads had received the sensor readings
    assert.equal((await node222006.getSensorReadings.call())[0], 9006);
    assert.equal((await node222006.getSensorReadings.call())[1], 9012);
    assert.equal((await node222006.getSensorReadings.call())[2], 9013);
    assert.equal((await node222008.getSensorReadings.call())[0], 9008);
    assert.equal((await node222008.getSensorReadings.call())[1], 9014);
    assert.equal((await node222008.getSensorReadings.call())[2], 9015);    

    // Check that the Layer 1 cluster heads had received the sensor readings
    assert.equal((await node222002.getSensorReadings.call())[0], 9002);
    assert.equal((await node222002.getSensorReadings.call())[1], 9006);
    assert.equal((await node222002.getSensorReadings.call())[2], 9007);
    assert.equal((await node222002.getSensorReadings.call())[3], 9012);
    assert.equal((await node222002.getSensorReadings.call())[4], 9013);
    assert.equal((await node222004.getSensorReadings.call())[0], 9004);
    assert.equal((await node222004.getSensorReadings.call())[1], 9008);
    assert.equal((await node222004.getSensorReadings.call())[2], 9009);
    assert.equal((await node222004.getSensorReadings.call())[3], 9010);
    assert.equal((await node222004.getSensorReadings.call())[4], 9011);
    assert.equal((await node222004.getSensorReadings.call())[5], 9014);
    assert.equal((await node222004.getSensorReadings.call())[6], 9015);

    // Check that the sink node had received the sensor readings
    assert.equal((await node111000.getSensorReadings.call())[0], 9001);
    assert.equal((await node111000.getSensorReadings.call())[1], 9002);
    assert.equal((await node111000.getSensorReadings.call())[2], 9003);
    assert.equal((await node111000.getSensorReadings.call())[3], 9004);
    assert.equal((await node111000.getSensorReadings.call())[4], 9005);
    assert.equal((await node111000.getSensorReadings.call())[5], 9006);
    assert.equal((await node111000.getSensorReadings.call())[6], 9007);
    assert.equal((await node111000.getSensorReadings.call())[7], 9008);
    assert.equal((await node111000.getSensorReadings.call())[8], 9009);
    assert.equal((await node111000.getSensorReadings.call())[9], 9010);
    assert.equal((await node111000.getSensorReadings.call())[10], 9011);
    assert.equal((await node111000.getSensorReadings.call())[11], 9012);
    assert.equal((await node111000.getSensorReadings.call())[12], 9013);
    assert.equal((await node111000.getSensorReadings.call())[13], 9014);
    assert.equal((await node111000.getSensorReadings.call())[14], 9015);
  });

  // TODO Add redundancy - put it in SensorNode perhaps?
  /*
CLUSTER HED NODE02:
[0, 1, 3, 6, 7]
CLUSTER HED NODE04:
[0, 3, 5, 7, 8, 9, 10, 11]
NODE07 (which received beacons from 02 and 04):
[2, 3, 4, 6, 8, 12, 13, 14]

OVERLAP of 02 and 07:
[3, 6]

OVERLAP of 04 and 07:
[3, 8]

OVERLAP of 02, 04 and 07:
[3]
  */
    
});
