// tutorials:
// * https://www.trufflesuite.com/docs/truffle/testing/writing-tests-in-javascript
// * https://kalis.me/assert-reverts-solidity-smart-contract-test-truffle/
// * https://ethereum.stackexchange.com/questions/48627/how-to-catch-revert-error-in-truffle-test-javascript#48629

// Contract abstractions provided by Truffle
// (TruffleContract instances)
const NodeEntries = artifacts.require("NodeEntries");
const NodeRoleEntries = artifacts.require("NodeRoleEntries");
const NodeEntryLib = artifacts.require("NodeEntryLib");

// Required for some test cases
const truffleAssert = require('truffle-assertions');

// NodeType enum values 
const NodeType = {
  Unassigned: 0,
  MemberNode: 1,
  ClusterHead: 2
};

// NodeRole enum values 
const NodeRole = {
  Default: 0,
  Sensor: 1,
  Controller: 2,
  Actuator: 3
};

// Convert the raw array returned by NodeEntries into a Node struct format
function toStruct(val) {
  convertedBeacons = [];
  convertedSReadings = [];

  // Convert the beacons
  for (var i = 0; i < val[5].length; i++) {
    var currBeacon = val[5][i];
    convertedBeacons.push({
      isSent: currBeacon[0],
      nextNetLevel: parseInt(currBeacon[1]),
      senderNodeAddr: parseInt(currBeacon[2]),
      withinRangeNodes: currBeacon[3].map(i => parseInt(i))
    });
  }

  // Convert the sensor readings
  for (var i = 0; i < val[7].length; i++) {
    var currSReading = val[7][i];
    convertedSReadings.push({
      reading: parseInt(currSReading[0]),
      exists: currSReading[1]
    });
  }

  return {
    nodeAddress: parseInt(val[0]),
    energyLevel: parseInt(val[1]),
    networkLevel: parseInt(val[2]),
    nodeType: val[3],
    
    links: {
      parentNode: parseInt(val[4][0]),
      childNodes: val[4][1].map(i => parseInt(i)),
      joinRequestNodes: val[4][2].map(i => parseInt(i)),
      numOfJoinRequests: parseInt(val[4][3]),
      withinRangeNodes: val[4][4].map(i => parseInt(i))
    },

    beacons: convertedBeacons,
    numOfBeacons: parseInt(val[6]),

    sensorReadings: convertedSReadings,
    numOfReadings: parseInt(val[8]),
    backupCHeads: val[9].map(i => parseInt(i)),
    isActive: val[10]

    // TODO: add a new version for the NodeRoleEntries data
  };
}

// Convert the raw array returned by NodeEntries into a console-readable string format
function toReadableString(val) {
  val = toStruct(val);
  var result = "";
  convertedBeacons = "";
  convertedSReadings = "";

  // Convert the beacons
  for (var i = 0; i < val.beacons.length; i++) {
    var currBeacon = val.beacons[i];
    convertedBeacons = convertedBeacons
    + "\t--------------------\n"
    + "\tisSent: " + currBeacon.isSent + "\n"
    + "\tnextNetLevel: " + currBeacon.nextNetLevel + "\n"
    + "\tsenderNodeAddr: " + currBeacon.senderNodeAddr + "\n"
    + "\twithinRangeNodes: " + currBeacon.withinRangeNodes + "\n";
  }

  // Convert the sensor readings
  for (var i = 0; i < val.sensorReadings.length; i++) {
    var currSReading = val.sensorReadings[i];
    convertedSReadings = convertedSReadings
    + "\t--------------------\n"
    + "\treading: " + currSReading.reading + "\n"
    + "\texists: " + currSReading.exists + "\n";
  }

  result = "==============================\n"
  + "nodeAddress:" + val.nodeAddress + "\n"
  + "energyLevel: " + val.energyLevel + "\n"
  + "networkLevel: " + val.networkLevel + "\n"
  + "nodeType: " + val.nodeType + "\n\n"

  + "links: {\n"
  + "\tparentNode: " + val.links.parentNode + "\n"
  + "\tchildNodes: " + val.links.childNodes + "\n"
  + "\tjoinRequestNodes: " + val.links.joinRequestNodes + "\n"
  + "\tnumOfJoinRequests: " + val.links.numOfJoinRequests + "\n"
  + "\twithinRangeNodes: " + val.links.withinRangeNodes + "\n"  
  + "}\n\n"


  + "beacons: {\n" + convertedBeacons + "\n}\n"
  + "numOfBeacons: " + val.numOfBeacons + "\n\n"

  + "sensorReadings: {\n" + convertedSReadings + "\n}\n"
  + "numOfReadings: " + val.numOfReadings + "\n"
  + "backupCHeads: " + val.backupCHeads + "\n"
  + "isActive: " + val.isActive + "\n\n";

  return result;
}

// Convert the raw array returned by NodeRoleEntries into a NodeRoleEntry struct format
function nrEntryToStruct(val) {
  return {
    nodeAddress: parseInt(val[0]),
    nodeRole: parseInt(val[1]),
    isTriggeringExternalService: val[2],
    triggerMessage: val[3],
    triggerThreshold: parseInt(val[4]),
    triggerCondition: parseInt(val[5])
  };
}

contract("NodeEntries - 3-layer network test case", async accounts => {
  let nodeEntries;
  let nodeRoleEntries;
  
  beforeEach(async () => {
    nodeEntries = await NodeEntries.deployed();
    nodeRoleEntries = await NodeRoleEntries.deployed();
  });

  /***********************************************
   * TEST - ADD NODES
   ***********************************************/
  it("should initialise everything correctly", async () => {
    //let numCandidates = await nodeEntries.numCandidates();
    //assert.equal(numVoters.toNumber(), 0);
    let numOfNodes = await nodeEntries.numOfNodes();
    assert.equal(numOfNodes, 0);
    let numOfLevels = await nodeEntries.numOfLevels();
    assert.equal(numOfLevels, 0);

  });

  
  it("should add DS.NodeEntry instances", async () => {
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
    await nodeEntries.addNode(111000, 100, [222001, 222002, 222003, 222004, 222005]);
  
    // Add neighbouring nodes
    // LAYER 1 NODES
    await nodeEntries.addNode(222001, 82, [111000, 222002, 222003]);
    await nodeEntries.addNode(222002, 88, [111000, 222006, 222007, 222003, 222001]);
    await nodeEntries.addNode(222003, 82, [111000, 222006, 222007, 222008, 222002, 222004, 222001, 222005]);
    await nodeEntries.addNode(222004, 95, [111000, 222007, 222008, 222009, 222003, 222010, 222005, 222011]);
    await nodeEntries.addNode(222005, 87, [111000, 222003, 222004, 222010, 222011]);
  
    // LAYER 2 NODES
    await nodeEntries.addNode(222006, 79, [222012, 222013, 222007, 222002, 222003]);
    await nodeEntries.addNode(222007, 61, [222012, 222013, 222014, 222006, 222008, 222002, 222003, 222004]);
    await nodeEntries.addNode(222008, 94, [222013, 222014, 222015, 222007, 222009, 222003, 222004, 222010]);
    await nodeEntries.addNode(222009, 95, [222014, 222015, 222008, 222004, 222010]);
    await nodeEntries.addNode(222010, 86, [222008, 222009, 222004, 222005, 222011]);
    await nodeEntries.addNode(222011, 93, [222004, 222010, 222005]);
  
    // LAYER 3 NODES
    await nodeEntries.addNode(222012, 71, [222013, 222006, 222007]);
    await nodeEntries.addNode(222013, 83, [222012, 222014, 222006, 222007, 222008]);
    await nodeEntries.addNode(222014, 78, [222013, 222015, 222007, 222008, 222009]);
    await nodeEntries.addNode(222015, 80, [222014, 222008, 222009]);
  
    // Ensure the values within this NodeEntryLib are as expected
    let firstNode = toStruct(await nodeEntries.getNodeAt.call(0));
    let firstNodeAddr = firstNode.nodeAddress;
    let firstNodeEnergyLevel = firstNode.energyLevel;
    assert.equal(firstNodeAddr, 111000);
    assert.equal(firstNodeEnergyLevel, 100);
  });
  
  it("should send beacon for Layer 1 nodes", async () => {
  
    // Set sink node as the 1st cluster head
    await nodeEntries.registerAsClusterHead(0, 111000);
  
    // Set its network level to be 0 (because sink node!)
    let sinkNode = await nodeEntries.getNodeEntry(111000);
    //console.log("parentNode = ");
    //console.log(await sinkNode.parentNode);
  
    // Send beacon from cluster head
    await nodeEntries.sendBeacon(111000);
  
    // Get the prospective child nodes
    let node1 = toStruct(await nodeEntries.getNodeEntry(222001));
    let node2 = toStruct(await nodeEntries.getNodeEntry(222002));
    let node3 = toStruct(await nodeEntries.getNodeEntry(222003));
    let node4 = toStruct(await nodeEntries.getNodeEntry(222004));
    let node5 = toStruct(await nodeEntries.getNodeEntry(222005));
  
    // Ensure network level is correct
    assert.equal(node1.networkLevel, 1);
    assert.equal(node2.networkLevel, 1);
    assert.equal(node3.networkLevel, 1);
    assert.equal(node4.networkLevel, 1);
    assert.equal(node5.networkLevel, 1);
  });
  
  it("should send join requests for Layer 1 nodes", async () => {
    // Make all nodes within range send a join request
    await nodeEntries.sendJoinRequests();
    let sinkNode = toStruct(await nodeEntries.getNodeEntry(111000));

    // Ensure the node addresses were added to list of join request nodes
    let node0 = toStruct(await nodeEntries.getNodeEntry(sinkNode.links.joinRequestNodes[0]));
    let node1 = toStruct(await nodeEntries.getNodeEntry(sinkNode.links.joinRequestNodes[1]));
    let node2 = toStruct(await nodeEntries.getNodeEntry(sinkNode.links.joinRequestNodes[2]));
    let node3 = toStruct(await nodeEntries.getNodeEntry(sinkNode.links.joinRequestNodes[3]));
    let node4 = toStruct(await nodeEntries.getNodeEntry(sinkNode.links.joinRequestNodes[4]));
    assert.equal(node0.nodeAddress, 222001);
    assert.equal(node1.nodeAddress, 222002);
    assert.equal(node2.nodeAddress, 222003);
    assert.equal(node3.nodeAddress, 222004);
    assert.equal(node4.nodeAddress, 222005);
  });
  
  it("should elect cluster heads for Layer 1 nodes", async () => {
    // 50% chance of cluster head being elected
    await nodeEntries.electClusterHeads(111000, 50);
  
    // Get the prospective child nodes
    let node1 = toStruct(await nodeEntries.getNodeEntry(222001));
    let node2 = toStruct(await nodeEntries.getNodeEntry(222002));
    let node3 = toStruct(await nodeEntries.getNodeEntry(222003));
    let node4 = toStruct(await nodeEntries.getNodeEntry(222004));
    let node5 = toStruct(await nodeEntries.getNodeEntry(222005));
    
    assert.equal(node2.nodeType, NodeType.ClusterHead);
    assert.equal(node4.nodeType, NodeType.ClusterHead);
    
    assert.equal(node1.nodeType, NodeType.MemberNode);
    assert.equal(node3.nodeType, NodeType.MemberNode);
    assert.equal(node5.nodeType, NodeType.MemberNode);
  });
  
  it("should send beacon for Layer 2 nodes", async () => {
    // Send beacon from Level 1 cluster heads (do this manually for now.)
    await nodeEntries.sendBeacon(222002);
    await nodeEntries.sendBeacon(222004);
  
    // Get the currently elected cluster heads
    let nodeSN = toStruct(await nodeEntries.getNodeEntry(111000));
    let nodeCH1 = toStruct(await nodeEntries.getNodeEntry(222002));
    let nodeCH2 = toStruct(await nodeEntries.getNodeEntry(222004));
  
    // Get the prospective child nodes
    let node06 = toStruct(await nodeEntries.getNodeEntry(222006));
    let node07 = toStruct(await nodeEntries.getNodeEntry(222007));
    let node08 = toStruct(await nodeEntries.getNodeEntry(222008));
    let node09 = toStruct(await nodeEntries.getNodeEntry(222009));
    let node10 = toStruct(await nodeEntries.getNodeEntry(222010));
    let node11 = toStruct(await nodeEntries.getNodeEntry(222011));
  
    // Ensure network level is correct
    assert.equal(nodeSN.networkLevel, 0);
    assert.equal(nodeCH1.networkLevel, 1);
    assert.equal(nodeCH2.networkLevel, 1);
    assert.equal(node06.networkLevel, 2);
    assert.equal(node07.networkLevel, 2);
    assert.equal(node08.networkLevel, 2);
    assert.equal(node09.networkLevel, 2);
    assert.equal(node10.networkLevel, 2);
    assert.equal(node11.networkLevel, 2);
  
    var node06NumBeacons = node06.numOfBeacons;
    for (var i = 0; i < node06NumBeacons; i++) {
      let node06BeaconData = node06.beacons[i+1];
      console.log("node06BeaconData = "); console.log(node06BeaconData);
    }
    var node07NumBeacons = node07.numOfBeacons;
    for (var i = 0; i < node07NumBeacons; i++) {
      let node07BeaconData = node07.beacons[i+1];
      console.log("node07BeaconData = "); console.log(node07BeaconData);
    }
    var node08NumBeacons = node08.numOfBeacons;
    for (var i = 0; i < node08NumBeacons; i++) {
      let node08BeaconData = node08.beacons[i+1];
      console.log("node08BeaconData = "); console.log(node08BeaconData);
    }
    var node09NumBeacons = node09.numOfBeacons;
    for (var i = 0; i < node09NumBeacons; i++) {
      let node09BeaconData = node09.beacons[i+1];
      console.log("node09BeaconData = "); console.log(node09BeaconData);
    }
    var node10NumBeacons = node10.numOfBeacons;
    for (var i = 0; i < node10NumBeacons; i++) {
      let node10BeaconData = node10.beacons[i+1];
      console.log("node10BeaconData = "); console.log(node10BeaconData);
    }
    var node11NumBeacons = node11.numOfBeacons;
    for (var i = 0; i < node11NumBeacons; i++) {
      let node11BeaconData = node11.beacons[i+1];
      console.log("node11BeaconData = "); console.log(node11BeaconData);
    }
  
  });
  
  it("should send join requests for Layer 2 nodes", async () => {
    // Make all nodes within range send a join request
    await nodeEntries.sendJoinRequests();
    let cHead1 = toStruct(await nodeEntries.getNodeEntry(222002));
    let cHead2 = toStruct(await nodeEntries.getNodeEntry(222004));
  
    // Ensure the node addresses were added to list of join request nodes
    let cHead1joinRequestNodes = await cHead1.links.joinRequestNodes;
    let node1_0 = toStruct(await nodeEntries.getNodeEntry(cHead1joinRequestNodes[0]));
    let node1_1 = toStruct(await nodeEntries.getNodeEntry(cHead1joinRequestNodes[1]));
    let cHead2joinRequestNodes = await cHead2.links.joinRequestNodes;
    let node2_0 = toStruct(await nodeEntries.getNodeEntry(cHead2joinRequestNodes[0]));
    let node2_1 = toStruct(await nodeEntries.getNodeEntry(cHead2joinRequestNodes[1]));
    let node2_2 = toStruct(await nodeEntries.getNodeEntry(cHead2joinRequestNodes[2]));
    let node2_3 = toStruct(await nodeEntries.getNodeEntry(cHead2joinRequestNodes[3]));
    assert.equal(node1_0.nodeAddress, 222006);
    assert.equal(node1_1.nodeAddress, 222007);
  
    assert.equal(node2_0.nodeAddress, 222008);
    assert.equal(node2_1.nodeAddress, 222009);
    assert.equal(node2_2.nodeAddress, 222010);
    assert.equal(node2_3.nodeAddress, 222011);
  });
  
  it("should elect cluster heads for Layer 2 nodes", async () => {
    // 50% chance of cluster head being elected
    await nodeEntries.electClusterHeads(222002, 50);
    await nodeEntries.electClusterHeads(222004, 50);
  
    // Get the prospective child nodes
    let node2_06 = toStruct(await nodeEntries.getNodeEntry(222006));
    let node2_07 = toStruct(await nodeEntries.getNodeEntry(222007));    
    let node4_08 = toStruct(await nodeEntries.getNodeEntry(222008));
    let node4_09 = toStruct(await nodeEntries.getNodeEntry(222009));
    let node4_10 = toStruct(await nodeEntries.getNodeEntry(222010));
    let node4_11 = toStruct(await nodeEntries.getNodeEntry(222011));
  
    assert.equal(node2_06.nodeType, NodeType.ClusterHead);
    assert.equal(node4_08.nodeType, NodeType.ClusterHead);
    assert.equal(node4_09.nodeType, NodeType.ClusterHead);
  
    assert.equal(node2_07.nodeType, NodeType.MemberNode);
    assert.equal(node4_10.nodeType, NodeType.MemberNode);
    assert.equal(node4_11.nodeType, NodeType.MemberNode);
  });
  
  it("should send beacon for Layer 3 nodes", async () => {
    // Send beacon from Level 2 cluster heads (do this manually for now.)
    await nodeEntries.sendBeacon(222006);
    await nodeEntries.sendBeacon(222008);
    await nodeEntries.sendBeacon(222009);
  
    // Get the currently elected cluster heads
    let nodeSN = toStruct(await nodeEntries.getNodeEntry(111000));
    let nodeCHL1_1 = toStruct(await nodeEntries.getNodeEntry(222002));
    let nodeCHL1_2 = toStruct(await nodeEntries.getNodeEntry(222004));
    let nodeCHL2_1 = toStruct(await nodeEntries.getNodeEntry(222006));
    let nodeCHL2_2 = toStruct(await nodeEntries.getNodeEntry(222008));
    let nodeCHL2_3 = toStruct(await nodeEntries.getNodeEntry(222009));
  
    // Get the prospective child nodes
    let node12 = toStruct(await nodeEntries.getNodeEntry(222012));
    let node13 = toStruct(await nodeEntries.getNodeEntry(222013));
    let node14 = toStruct(await nodeEntries.getNodeEntry(222014));
    let node15 = toStruct(await nodeEntries.getNodeEntry(222015));
  
    // Ensure network level is correct
    assert.equal(nodeSN.networkLevel, 0);
    assert.equal(nodeCHL1_1.networkLevel, 1);
    assert.equal(nodeCHL1_2.networkLevel, 1);
    assert.equal(nodeCHL2_1.networkLevel, 2);
    assert.equal(nodeCHL2_2.networkLevel, 2);
    assert.equal(nodeCHL2_3.networkLevel, 2);
    assert.equal(node12.networkLevel, 3);
    assert.equal(node13.networkLevel, 3);
    assert.equal(node14.networkLevel, 3);
    assert.equal(node15.networkLevel, 3);
  });
  
  it("should send join requests for Layer 3 nodes", async () => {
    // Make all nodes within range send a join request
    await nodeEntries.sendJoinRequests();
    let cHead1 = toStruct(await nodeEntries.getNodeEntry(222006));
    let cHead2 = toStruct(await nodeEntries.getNodeEntry(222008));
    let cHead3 = toStruct(await nodeEntries.getNodeEntry(222009)); // this one has no nodes to rule over as 222008 has taken the last one
  
    // Ensure the node addresses were added to list of join request nodes
    let cHead1joinRequestNodes = cHead1.links.joinRequestNodes;
    let node1_0 = toStruct(await nodeEntries.getNodeEntry(cHead1joinRequestNodes[0]));
    let node1_1 = toStruct(await nodeEntries.getNodeEntry(cHead1joinRequestNodes[1]));
    assert.equal(node1_0.nodeAddress, 222012);
    assert.equal(node1_1.nodeAddress, 222013);
  
    let cHead2joinRequestNodes = cHead2.links.joinRequestNodes;
    let node2_0 = toStruct(await nodeEntries.getNodeEntry(cHead2joinRequestNodes[0]));
    let node2_1 = toStruct(await nodeEntries.getNodeEntry(cHead2joinRequestNodes[1]));
    assert.equal(node2_0.nodeAddress, 222014);
    assert.equal(node2_1.nodeAddress, 222015);
    
  });
  
  it("should find the backup cluster heads for Layer 3 nodes to connect to", async () => {
    /*
    CLUSTER HED NODE 02 withinRangeNodes:
    [0, 1, 3, 6, 7]
    CLUSTER HED NODE 04 withinRangeNodes:
    [0, 3, 5, 7, 8, 9, 10, 11]
    NODE 07 withinRangeNodes (which received beacons from 02 and 04):
    [2, 3, 4, 6, 8, 12, 13, 14]

    OVERLAP of 02 and 07:
    [3, 6]

    OVERLAP of 04 and 07:
    [3, 8]

    OVERLAP of 02, 04 and 07:
    [3]
    */
    await nodeEntries.identifyBackupClusterHeads();
    
    console.log("::::: NODE 222002! :::::");
    let node222002 = toStruct(await nodeEntries.getNodeEntry(222002));
    assert.equal(node222002.backupCHeads[0], 222001);
    assert.equal(node222002.backupCHeads[1], 222003);
    console.log("::::: NODE 222004! :::::");
    let node222004 = toStruct(await nodeEntries.getNodeEntry(222004));
    assert.equal(node222004.backupCHeads[0], 222003);
    assert.equal(node222004.backupCHeads[1], 222005);
    console.log("::::: NODE 222007! :::::");
    let node222007 = toStruct(await nodeEntries.getNodeEntry(222007));
    assert.equal(node222007.backupCHeads[0], 222003);
  });
  
  it("should elect cluster heads for Layer 3 nodes", async () => {
    // 50% chance of cluster head being elected
    await nodeEntries.electClusterHeads(222006, 50);
    await nodeEntries.electClusterHeads(222008, 50);
    await nodeEntries.electClusterHeads(222009, 50);
  
    // Get the prospective child nodes
    let node6_12 = toStruct(await nodeEntries.getNodeEntry(222012));
    let node6_13 = toStruct(await nodeEntries.getNodeEntry(222013));    
    let node8_14 = toStruct(await nodeEntries.getNodeEntry(222014));
    let node8_15 = toStruct(await nodeEntries.getNodeEntry(222015));
  
    assert.equal(node6_13.nodeType, NodeType.ClusterHead);
    assert.equal(node8_15.nodeType, NodeType.ClusterHead);
  
    assert.equal(node6_12.nodeType, NodeType.MemberNode);
    assert.equal(node8_14.nodeType, NodeType.MemberNode);
    
  });
  
  it("should send sensor readings to sink node", async () => {
    // Simulate reading values from each sensor node
    await nodeEntries.readSensorInput(37011, 222001); // just to trigger the response
    await nodeEntries.readSensorInput(9002, 222002);
    await nodeEntries.readSensorInput(9003, 222003);
    await nodeEntries.readSensorInput(9004, 222004);
    await nodeEntries.readSensorInput(9005, 222005);
    await nodeEntries.readSensorInput(9006, 222006);
    await nodeEntries.readSensorInput(9007, 222007);
    await nodeEntries.readSensorInput(9008, 222008);
    await nodeEntries.readSensorInput(9009, 222009);
    await nodeEntries.readSensorInput(9010, 222010);
    await nodeEntries.readSensorInput(9011, 222011);
    await nodeEntries.readSensorInput(9012, 222012);
    await nodeEntries.readSensorInput(9013, 222013);
    await nodeEntries.readSensorInput(9014, 222014);
    await nodeEntries.readSensorInput(9015, 222015);

    let node111000 = toStruct(await nodeEntries.getNodeEntry(111000));
    let node222001 = toStruct(await nodeEntries.getNodeEntry(222001));
    let node222002 = toStruct(await nodeEntries.getNodeEntry(222002));
    let node222003 = toStruct(await nodeEntries.getNodeEntry(222003));
    let node222004 = toStruct(await nodeEntries.getNodeEntry(222004));
    let node222005 = toStruct(await nodeEntries.getNodeEntry(222005));
    let node222006 = toStruct(await nodeEntries.getNodeEntry(222006));
    let node222007 = toStruct(await nodeEntries.getNodeEntry(222007));
    let node222008 = toStruct(await nodeEntries.getNodeEntry(222008));
    let node222009 = toStruct(await nodeEntries.getNodeEntry(222009));
    let node222010 = toStruct(await nodeEntries.getNodeEntry(222010));
    let node222011 = toStruct(await nodeEntries.getNodeEntry(222011));
    let node222012 = toStruct(await nodeEntries.getNodeEntry(222012));
    let node222013 = toStruct(await nodeEntries.getNodeEntry(222013));
    let node222014 = toStruct(await nodeEntries.getNodeEntry(222014));
    let node222015 = toStruct(await nodeEntries.getNodeEntry(222015));
  
    // Check that all sensor nodes got their readings
    // node: sensorReadings[0] is a dummy reading to help detect null values,
    assert.equal(node222001.sensorReadings[1].reading, 37011);
    assert.equal(node222003.sensorReadings[1].reading, 9003);
    assert.equal(node222005.sensorReadings[1].reading, 9005);
    assert.equal(node222007.sensorReadings[1].reading, 9007);
    assert.equal(node222009.sensorReadings[1].reading, 9009);
    assert.equal(node222010.sensorReadings[1].reading, 9010);
    assert.equal(node222011.sensorReadings[1].reading, 9011);
    assert.equal(node222012.sensorReadings[1].reading, 9012);
    assert.equal(node222013.sensorReadings[1].reading, 9013);
    assert.equal(node222014.sensorReadings[1].reading, 9014);
    assert.equal(node222015.sensorReadings[1].reading, 9015);
  
    // Check that the Layer 2 cluster heads had received the sensor readings
    assert.equal(node222006.sensorReadings[1].reading, 9006);
    assert.equal(node222006.sensorReadings[2].reading, 9012);
    assert.equal(node222006.sensorReadings[3].reading, 9013);
    assert.equal(node222008.sensorReadings[1].reading, 9008);
    assert.equal(node222008.sensorReadings[2].reading, 9014);
    assert.equal(node222008.sensorReadings[3].reading, 9015);    
  
    // Check that the Layer 1 cluster heads had received the sensor readings
    assert.equal(node222002.sensorReadings[1].reading, 9002);
    assert.equal(node222002.sensorReadings[2].reading, 9006);
    assert.equal(node222002.sensorReadings[3].reading, 9007);
    assert.equal(node222002.sensorReadings[4].reading, 9012);
    assert.equal(node222002.sensorReadings[5].reading, 9013);
    assert.equal(node222004.sensorReadings[1].reading, 9004);
    assert.equal(node222004.sensorReadings[2].reading, 9008);
    assert.equal(node222004.sensorReadings[3].reading, 9009);
    assert.equal(node222004.sensorReadings[4].reading, 9010);
    assert.equal(node222004.sensorReadings[5].reading, 9011);
    assert.equal(node222004.sensorReadings[6].reading, 9014);
    assert.equal(node222004.sensorReadings[7].reading, 9015);
  
    // Check that the sink node had received the sensor readings
    assert.equal(node111000.sensorReadings[1].reading, 37011);
    assert.equal(node111000.sensorReadings[2].reading, 9002);
    assert.equal(node111000.sensorReadings[3].reading, 9003);
    assert.equal(node111000.sensorReadings[4].reading, 9004);
    assert.equal(node111000.sensorReadings[5].reading, 9005);
    assert.equal(node111000.sensorReadings[6].reading, 9006);
    assert.equal(node111000.sensorReadings[7].reading, 9007);
    assert.equal(node111000.sensorReadings[8].reading, 9008);
    assert.equal(node111000.sensorReadings[9].reading, 9009);
    assert.equal(node111000.sensorReadings[10].reading, 9010);
    assert.equal(node111000.sensorReadings[11].reading, 9011);
    assert.equal(node111000.sensorReadings[12].reading, 9012);
    assert.equal(node111000.sensorReadings[13].reading, 9013);
    assert.equal(node111000.sensorReadings[14].reading, 9014);
    assert.equal(node111000.sensorReadings[15].reading, 9015);

    // console.log((await nodeEntries.getAllNodes()).map(node => toStruct(node)).map(function(nodeStruct) {
    //   return {
    //     nodeAddress: nodeStruct.nodeAddress, 
    //     backupCHeads: nodeStruct.backupCHeads
    //   };
    // }));
  });
  
  it("should be able to assign roles to nodes", async () => {
    // Commented out the assignAsController() calls since cluster heads
    // should already be assigned as Controllers
    //await nodeEntries.assignAsController(111000);
    await nodeRoleEntries.assignAsSensor(222001);
    //await nodeEntries.assignAsController(222002);
    await nodeRoleEntries.assignAsSensor(222003);
    //await nodeEntries.assignAsController(222004);
    await nodeRoleEntries.assignAsActuator(222005, "Activating sprinklers!");
    //await nodeEntries.assignAsController(222006);
    await nodeRoleEntries.assignAsActuator(222007, "Contacting the RFS.");
    //await nodeEntries.assignAsController(222008);
    await nodeRoleEntries.assignAsSensor(222009);
    await nodeRoleEntries.assignAsActuator(222010, "Activating emergency sirens!");
    await nodeRoleEntries.assignAsActuator(222011, "Send evacuation SMS to all phones");
    await nodeRoleEntries.assignAsSensor(222012);
    await nodeRoleEntries.assignAsSensor(222013);
    await nodeRoleEntries.assignAsSensor(222014);
    await nodeRoleEntries.assignAsSensor(222015);

    let nodeRoleEntry111000 = nrEntryToStruct(await nodeRoleEntries.getNREntry(111000));
    let nodeRoleEntry222001 = nrEntryToStruct(await nodeRoleEntries.getNREntry(222001));
    let nodeRoleEntry222002 = nrEntryToStruct(await nodeRoleEntries.getNREntry(222002));
    let nodeRoleEntry222003 = nrEntryToStruct(await nodeRoleEntries.getNREntry(222003));
    let nodeRoleEntry222004 = nrEntryToStruct(await nodeRoleEntries.getNREntry(222004));
    let nodeRoleEntry222005 = nrEntryToStruct(await nodeRoleEntries.getNREntry(222005));
    let nodeRoleEntry222006 = nrEntryToStruct(await nodeRoleEntries.getNREntry(222006));
    let nodeRoleEntry222007 = nrEntryToStruct(await nodeRoleEntries.getNREntry(222007));
    let nodeRoleEntry222008 = nrEntryToStruct(await nodeRoleEntries.getNREntry(222008));
    let nodeRoleEntry222009 = nrEntryToStruct(await nodeRoleEntries.getNREntry(222009));
    let nodeRoleEntry222010 = nrEntryToStruct(await nodeRoleEntries.getNREntry(222010));
    let nodeRoleEntry222011 = nrEntryToStruct(await nodeRoleEntries.getNREntry(222011));
    let nodeRoleEntry222012 = nrEntryToStruct(await nodeRoleEntries.getNREntry(222012));
    let nodeRoleEntry222013 = nrEntryToStruct(await nodeRoleEntries.getNREntry(222013));
    let nodeRoleEntry222014 = nrEntryToStruct(await nodeRoleEntries.getNREntry(222014));
    let nodeRoleEntry222015 = nrEntryToStruct(await nodeRoleEntries.getNREntry(222015));

    assert.equal(nodeRoleEntry111000.nodeRole, NodeRole.Controller);
    assert.equal(nodeRoleEntry222001.nodeRole, NodeRole.Sensor);
    assert.equal(nodeRoleEntry222002.nodeRole, NodeRole.Controller);
    assert.equal(nodeRoleEntry222003.nodeRole, NodeRole.Sensor);
    assert.equal(nodeRoleEntry222004.nodeRole, NodeRole.Controller);
    assert.equal(nodeRoleEntry222005.nodeRole, NodeRole.Actuator);
    assert.equal(nodeRoleEntry222006.nodeRole, NodeRole.Controller);
    assert.equal(nodeRoleEntry222007.nodeRole, NodeRole.Actuator);
    assert.equal(nodeRoleEntry222008.nodeRole, NodeRole.Controller);
    assert.equal(nodeRoleEntry222009.nodeRole, NodeRole.Sensor);
    assert.equal(nodeRoleEntry222010.nodeRole, NodeRole.Actuator);
    assert.equal(nodeRoleEntry222011.nodeRole, NodeRole.Actuator);
    assert.equal(nodeRoleEntry222012.nodeRole, NodeRole.Sensor);
    assert.equal(nodeRoleEntry222013.nodeRole, NodeRole.Sensor);
    assert.equal(nodeRoleEntry222014.nodeRole, NodeRole.Sensor);
    assert.equal(nodeRoleEntry222015.nodeRole, NodeRole.Sensor);
    
  });
  
  it("should be able to respond to sensor input", async () => {
    await nodeEntries.respondToSensorInput(111000);

    let nodeRoleEntry222005 = nrEntryToStruct(await nodeRoleEntries.getNREntry(222005));
    let nodeRoleEntry222007 = nrEntryToStruct(await nodeRoleEntries.getNREntry(222007));
    let nodeRoleEntry222010 = nrEntryToStruct(await nodeRoleEntries.getNREntry(222010));
    let nodeRoleEntry222011 = nrEntryToStruct(await nodeRoleEntries.getNREntry(222011));

    // These actuators should be triggering an external service (in this simulation, just set isTriggeringExternalService to true)
    assert.equal(nodeRoleEntry222005.isTriggeringExternalService, true);
    assert.equal(nodeRoleEntry222007.isTriggeringExternalService, true);
    assert.equal(nodeRoleEntry222010.isTriggeringExternalService, true);
    assert.equal(nodeRoleEntry222011.isTriggeringExternalService, true);
    
    console.log(toReadableString(await nodeEntries.getNodeEntry(222005)));
    
    // (await nodeEntries.getAllNodes()).map(
    //   function(node) {
    //     console.log(toStruct(node)); 
    //   }
    // );
    
    // console.log((await nodeRoleEntries.getAllNodes()).map(node => toStruct(node)).map(function(nodeStruct) {
    //   return {
    //     nodeAddress: nodeStruct.nodeAddress, 
    //     sensorReadings: nodeStruct.sensorReadings.map(x => x.reading),
    //     nodeRole: nodeStruct.ev.nodeRole,
    //     isTriggeringExternalService: nodeStruct.ev.isTriggeringExternalService,
    //     triggerMessage: nodeStruct.ev.triggerMessage
    //   };
    // }));


  });

  
  it("should be able to send reading to sink node even if its cluster head has become inactive", async () => {
    // Disable node 222002
    await nodeEntries.deactivateNode(222002);
    
    // Send sensor reading from node 222007
    await nodeEntries.readSensorInput(700700, 222007);

    let node111000 = toStruct(await nodeEntries.getNodeEntry(111000));
    let node222002 = toStruct(await nodeEntries.getNodeEntry(222002));
    let node222003 = toStruct(await nodeEntries.getNodeEntry(222003));
    let node222004 = toStruct(await nodeEntries.getNodeEntry(222004));
    let node222007 = toStruct(await nodeEntries.getNodeEntry(222007));

    // console.log((await nodeEntries.getAllNodes()).map(node => toStruct(node)).map(function(nodeStruct) {
    //   return {
    //     nodeAddress: nodeStruct.nodeAddress, 
    //     parentNode: nodeStruct.parentNode, 
    //     sensorReadings: nodeStruct.sensorReadings.map(sReading => sReading.reading),
    //     nodeType: nodeStruct.nodeType,
    //     isActive: nodeStruct.isActive
    //   };
    // }));

  
    assert.equal(node222007.sensorReadings[2].reading, 700700);
    
    // should be untouched
    assert.equal(node222002.sensorReadings[5].reading, 9013);
    assert.equal(node222004.sensorReadings[7].reading, 9015);
    //assert.equal(node222002.sensorReadings[6].reading, 700700); // should NOT happen
    //assert.equal(node222004.sensorReadings[8].reading, 700700); // should NOT happen
    
    // new cluster head should get the reading
    assert.equal(node222003.sensorReadings[2].reading, 9007); // actually a duplicate, should not be in (need to re-do this one)
    assert.equal(node222003.sensorReadings[3].reading, 700700);
    
    // sink node should get the reading too
    assert.equal(node111000.sensorReadings[16].reading, 700700);
  });
    
});
