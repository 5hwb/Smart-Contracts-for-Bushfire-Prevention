// tutorials:
// * https://www.trufflesuite.com/docs/truffle/testing/writing-tests-in-javascript
// * https://kalis.me/assert-reverts-solidity-smart-contract-test-truffle/
// * https://ethereum.stackexchange.com/questions/48627/how-to-catch-revert-error-in-truffle-test-javascript#48629

// Contract abstractions provided by Truffle
// (TruffleContract instances)
const NetworkFormation = artifacts.require("NetworkFormation");
const SensorNode = artifacts.require("SensorNode");

// Required for some test cases
const truffleAssert = require('truffle-assertions');

// Convert the raw array returned by NetworkFormation into a Node struct format
function toStruct(val) {
  convertedBeacons = [];
  convertedSReadings = [];

  // Convert the beacons
  for (var i = 0; i < val[11].length; i++) {
    var currBeacon = val[11][i];
    convertedBeacons.push({
      isSent: currBeacon[0],
      nextNetLevel: parseInt(currBeacon[1]),
      senderNodeAddr: parseInt(currBeacon[2]),
      withinRangeNodes: currBeacon[3].map(i => parseInt(i))
    });
  }

  // Convert the sensor readings
  for (var i = 0; i < val[13].length; i++) {
    var currSReading = val[13][i];
    convertedSReadings.push({
      reading: parseInt(currSReading[0]),
      exists: currSReading[1]
    });
  }

  return {
    nodeID: parseInt(val[0]),
    nodeAddress: parseInt(val[1]),
    energyLevel: parseInt(val[2]),
    networkLevel: parseInt(val[3]),
    numOfOneHopClusterHeads: parseInt(val[4]),
    nodeType: val[5],
    
    parentNode: parseInt(val[6]),
    childNodes: val[7].map(i => parseInt(i)),
    joinRequestNodes: val[8].map(i => parseInt(i)),
    numOfJoinRequests: parseInt(val[9]),
    withinRangeNodes: val[10].map(i => parseInt(i)),

    beacons: convertedBeacons,
    numOfBeacons: parseInt(val[12]),

    sensorReadings: convertedSReadings,
    numOfReadings: parseInt(val[14]),
    backupCHeads: val[15].map(i => parseInt(i)),
    isActive: val[16],
    nodeRole: val[17]
  };
}

// Convert the raw array returned by NetworkFormation into a console-readable string format
function toReadableString(val) {
  var result = "";
  convertedBeacons = "";
  convertedSReadings = "";

  // Convert the beacons
  for (var i = 0; i < val[11].length; i++) {
    var currBeacon = val[11][i];
    convertedBeacons = convertedBeacons + "\n"
    + "\t--------------------\n"
    + "\tisSent: " +  currBeacon[0] + "\n"
    + "\tnextNetLevel: " +  parseInt(currBeacon[1]) + "\n"
    + "\tsenderNodeAddr: " +  parseInt(currBeacon[2]) + "\n"
    + "\twithinRangeNodes: " +  currBeacon[3].map(i => parseInt(i));
  }

  // Convert the sensor readings
  for (var i = 0; i < val[13].length; i++) {
    var currSReading = val[13][i];
    convertedSReadings = convertedSReadings + "\n"
    + "\t--------------------\n"
    + "\treading: " +  parseInt(currSReading[0]) + "\n"
    + "\texists: " +  currSReading[1];
  }
  
  result = "==============================\n"
  + "nodeID: " + parseInt(val[0]) + "\n"
  + "nodeAddress:" + parseInt(val[1]) + "\n"
  + "energyLevel: " +  parseInt(val[2]) + "\n"
  + "networkLevel: " +  parseInt(val[3]) + "\n"
  + "numOfOneHopClusterHeads: " +  parseInt(val[4]) + "\n"
  + "nodeType: " +  val[5] + "\n\n"

  + "parentNode: " +  parseInt(val[6]) + "\n"
  + "childNodes: " +  val[7].map(i => parseInt(i)) + "\n"
  + "joinRequestNodes: " +  val[8].map(i => parseInt(i)) + "\n"
  + "numOfJoinRequests: " +  parseInt(val[9]) + "\n"
  + "withinRangeNodes: " +  val[10].map(i => parseInt(i)) + "\n\n"

  + "beacons: {\n" +  convertedBeacons + "\n}\n"
  + "numOfBeacons: " +  parseInt(val[12]) + "\n\n"

  + "sensorReadings: {\n" +  convertedSReadings + "\n}\n"
  + "numOfReadings: " +  parseInt(val[14]) + "\n"
  + "backupCHeads: " +  val[15].map(i => parseInt(i)) + "\n"
  + "isActive: " +  val[16] + "\n"
  + "nodeRole: " +  val[17] + "\n";

  return result;
}

contract("NetworkFormation - 3-layer network test case", async accounts => {
  let networkFormation;
  
  beforeEach(async () => {
    networkFormation = await NetworkFormation.deployed();
  });

  /***********************************************
   * TEST - ADD NODES
   ***********************************************/
  it("should initialise everything correctly", async () => {
    //let numCandidates = await networkFormation.numCandidates();
    //assert.equal(numVoters.toNumber(), 0);
    let numOfNodes = await networkFormation.numOfNodes();
    assert.equal(numOfNodes, 0);
    let numOfLevels = await networkFormation.numOfLevels();
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
    await networkFormation.addNode(1, 111000, 100, [222001, 222002, 222003, 222004, 222005]);
  
    // Add neighbouring nodes
    // LAYER 1 NODES
    await networkFormation.addNode(2, 222001, 82, [111000, 222002, 222003]);
    await networkFormation.addNode(3, 222002, 88, [111000, 222006, 222007, 222003, 222001]);
    await networkFormation.addNode(4, 222003, 82, [111000, 222006, 222007, 222008, 222002, 222004, 222001, 222005]);
    await networkFormation.addNode(5, 222004, 95, [111000, 222007, 222008, 222009, 222003, 222010, 222005, 222011]);
    await networkFormation.addNode(6, 222005, 87, [111000, 222003, 222004, 222010, 222011]);
  
    // LAYER 2 NODES
    await networkFormation.addNode( 7, 222006, 79, [222012, 222013, 222007, 222002, 222003]);
    await networkFormation.addNode( 8, 222007, 61, [222012, 222013, 222014, 222006, 222008, 222002, 222003, 222004]);
    await networkFormation.addNode( 9, 222008, 94, [222013, 222014, 222015, 222007, 222009, 222003, 222004, 222010]);
    await networkFormation.addNode(10, 222009, 95, [222014, 222015, 222008, 222004, 222010]);
    await networkFormation.addNode(11, 222010, 86, [222008, 222009, 222004, 222005, 222011]);
    await networkFormation.addNode(12, 222011, 93, [222004, 222010, 222005]);
  
    // LAYER 3 NODES
    await networkFormation.addNode(13, 222012, 71, [222013, 222006, 222007]);
    await networkFormation.addNode(14, 222013, 83, [222012, 222014, 222006, 222007, 222008]);
    await networkFormation.addNode(15, 222014, 78, [222013, 222015, 222007, 222008, 222009]);
    await networkFormation.addNode(16, 222015, 80, [222014, 222008, 222009]);
  
    // Ensure the values within this SensorNode is as expected
    let firstNode = toStruct(await networkFormation.getNodeAt.call(0));
    let firstNodeID = firstNode.nodeID;
    let firstNodeAddr = firstNode.nodeAddress;
    let firstNodeEnergyLevel = firstNode.energyLevel;
    assert.equal(firstNodeID, 1);
    assert.equal(firstNodeAddr, 111000);
    assert.equal(firstNodeEnergyLevel, 100);
  });
  
  it("should send beacon for Layer 1 nodes", async () => {
  
    // Set sink node as the 1st cluster head
    await networkFormation.registerAsClusterHead(0, 111000);
  
    // Set its network level to be 0 (because sink node!)
    let sinkNode = await networkFormation.getNodeAsMemory(111000);
    //console.log("parentNode = ");
    //console.log(await sinkNode.parentNode);
  
    // Send beacon from cluster head
    await networkFormation.sendBeacon(111000);
  
    // Get the prospective child nodes
    let node1 = toStruct(await networkFormation.getNodeAsMemory(222001));
    let node2 = toStruct(await networkFormation.getNodeAsMemory(222002));
    let node3 = toStruct(await networkFormation.getNodeAsMemory(222003));
    let node4 = toStruct(await networkFormation.getNodeAsMemory(222004));
    let node5 = toStruct(await networkFormation.getNodeAsMemory(222005));
  
    // Ensure network level is correct
    assert.equal(node1.networkLevel, 1);
    assert.equal(node2.networkLevel, 1);
    assert.equal(node3.networkLevel, 1);
    assert.equal(node4.networkLevel, 1);
    assert.equal(node5.networkLevel, 1);
  });
  
  it("should send join requests for Layer 1 nodes", async () => {
    // Make all nodes within range send a join request
    await networkFormation.sendJoinRequests();
    let sinkNode = toStruct(await networkFormation.getNodeAsMemory(111000));

    // Ensure the node addresses were added to list of join request nodes
    let node0 = toStruct(await networkFormation.getNodeAsMemory(sinkNode.joinRequestNodes[0]));
    let node1 = toStruct(await networkFormation.getNodeAsMemory(sinkNode.joinRequestNodes[1]));
    let node2 = toStruct(await networkFormation.getNodeAsMemory(sinkNode.joinRequestNodes[2]));
    let node3 = toStruct(await networkFormation.getNodeAsMemory(sinkNode.joinRequestNodes[3]));
    let node4 = toStruct(await networkFormation.getNodeAsMemory(sinkNode.joinRequestNodes[4]));
    assert.equal(node0.nodeAddress, 222001);
    assert.equal(node1.nodeAddress, 222002);
    assert.equal(node2.nodeAddress, 222003);
    assert.equal(node3.nodeAddress, 222004);
    assert.equal(node4.nodeAddress, 222005);
  });
  
  // NodeType enum values 
  const NodeType = {
    Unassigned: '0',
    MemberNode: '1',
    ClusterHead: '2'
  };
  
  // NodeRole enum values 
  const NodeRole = {
    Default: '0',
    Sensor: '1',
    Controller: '2',
    Actuator: '3'
  };
  
  it("should elect cluster heads for Layer 1 nodes", async () => {
    // 50% chance of cluster head being elected
    await networkFormation.electClusterHeads(111000, 50);
  
    // Get the prospective child nodes
    let node1 = toStruct(await networkFormation.getNodeAsMemory(222001));
    let node2 = toStruct(await networkFormation.getNodeAsMemory(222002));
    let node3 = toStruct(await networkFormation.getNodeAsMemory(222003));
    let node4 = toStruct(await networkFormation.getNodeAsMemory(222004));
    let node5 = toStruct(await networkFormation.getNodeAsMemory(222005));
    
    assert.equal(node2.nodeType, NodeType.ClusterHead);
    assert.equal(node4.nodeType, NodeType.ClusterHead);
    
    assert.equal(node1.nodeType, NodeType.MemberNode);
    assert.equal(node3.nodeType, NodeType.MemberNode);
    assert.equal(node5.nodeType, NodeType.MemberNode);
  });
  
  it("should send beacon for Layer 2 nodes", async () => {
    // Send beacon from Level 1 cluster heads (do this manually for now.)
    await networkFormation.sendBeacon(222002);
    await networkFormation.sendBeacon(222004);
  
    // Get the currently elected cluster heads
    let nodeSN = toStruct(await networkFormation.getNodeAsMemory(111000));
    let nodeCH1 = toStruct(await networkFormation.getNodeAsMemory(222002));
    let nodeCH2 = toStruct(await networkFormation.getNodeAsMemory(222004));
  
    // Get the prospective child nodes
    let node06 = toStruct(await networkFormation.getNodeAsMemory(222006));
    let node07 = toStruct(await networkFormation.getNodeAsMemory(222007));
    let node08 = toStruct(await networkFormation.getNodeAsMemory(222008));
    let node09 = toStruct(await networkFormation.getNodeAsMemory(222009));
    let node10 = toStruct(await networkFormation.getNodeAsMemory(222010));
    let node11 = toStruct(await networkFormation.getNodeAsMemory(222011));
  
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
    await networkFormation.sendJoinRequests();
    let cHead1 = toStruct(await networkFormation.getNodeAsMemory(222002));
    let cHead2 = toStruct(await networkFormation.getNodeAsMemory(222004));
  
    // Ensure the node addresses were added to list of join request nodes
    let cHead1joinRequestNodes = await cHead1.joinRequestNodes;
    let node1_0 = toStruct(await networkFormation.getNodeAsMemory(cHead1joinRequestNodes[0]));
    let node1_1 = toStruct(await networkFormation.getNodeAsMemory(cHead1joinRequestNodes[1]));
    let cHead2joinRequestNodes = await cHead2.joinRequestNodes;
    let node2_0 = toStruct(await networkFormation.getNodeAsMemory(cHead2joinRequestNodes[0]));
    let node2_1 = toStruct(await networkFormation.getNodeAsMemory(cHead2joinRequestNodes[1]));
    let node2_2 = toStruct(await networkFormation.getNodeAsMemory(cHead2joinRequestNodes[2]));
    let node2_3 = toStruct(await networkFormation.getNodeAsMemory(cHead2joinRequestNodes[3]));
    assert.equal(node1_0.nodeAddress, 222006);
    assert.equal(node1_1.nodeAddress, 222007);
  
    assert.equal(node2_0.nodeAddress, 222008);
    assert.equal(node2_1.nodeAddress, 222009);
    assert.equal(node2_2.nodeAddress, 222010);
    assert.equal(node2_3.nodeAddress, 222011);
  });
  
  it("should elect cluster heads for Layer 2 nodes", async () => {
    // 50% chance of cluster head being elected
    await networkFormation.electClusterHeads(222002, 50);
    await networkFormation.electClusterHeads(222004, 50);
  
    // Get the prospective child nodes
    let node2_06 = toStruct(await networkFormation.getNodeAsMemory(222006));
    let node2_07 = toStruct(await networkFormation.getNodeAsMemory(222007));    
    let node4_08 = toStruct(await networkFormation.getNodeAsMemory(222008));
    let node4_09 = toStruct(await networkFormation.getNodeAsMemory(222009));
    let node4_10 = toStruct(await networkFormation.getNodeAsMemory(222010));
    let node4_11 = toStruct(await networkFormation.getNodeAsMemory(222011));
  
    assert.equal(node2_06.nodeType, NodeType.ClusterHead);
    assert.equal(node4_08.nodeType, NodeType.ClusterHead);
    assert.equal(node4_09.nodeType, NodeType.ClusterHead);
  
    assert.equal(node2_07.nodeType, NodeType.MemberNode);
    assert.equal(node4_10.nodeType, NodeType.MemberNode);
    assert.equal(node4_11.nodeType, NodeType.MemberNode);
  });
  
  it("should send beacon for Layer 3 nodes", async () => {
    // Send beacon from Level 2 cluster heads (do this manually for now.)
    await networkFormation.sendBeacon(222006);
    await networkFormation.sendBeacon(222008);
    await networkFormation.sendBeacon(222009);
  
    // Get the currently elected cluster heads
    let nodeSN = toStruct(await networkFormation.getNodeAsMemory(111000));
    let nodeCHL1_1 = toStruct(await networkFormation.getNodeAsMemory(222002));
    let nodeCHL1_2 = toStruct(await networkFormation.getNodeAsMemory(222004));
    let nodeCHL2_1 = toStruct(await networkFormation.getNodeAsMemory(222006));
    let nodeCHL2_2 = toStruct(await networkFormation.getNodeAsMemory(222008));
    let nodeCHL2_3 = toStruct(await networkFormation.getNodeAsMemory(222009));
  
    // Get the prospective child nodes
    let node12 = toStruct(await networkFormation.getNodeAsMemory(222012));
    let node13 = toStruct(await networkFormation.getNodeAsMemory(222013));
    let node14 = toStruct(await networkFormation.getNodeAsMemory(222014));
    let node15 = toStruct(await networkFormation.getNodeAsMemory(222015));
  
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
    await networkFormation.sendJoinRequests();
    let cHead1 = toStruct(await networkFormation.getNodeAsMemory(222006));
    let cHead2 = toStruct(await networkFormation.getNodeAsMemory(222008));
    let cHead3 = toStruct(await networkFormation.getNodeAsMemory(222009)); // this one has no nodes to rule over as 222008 has taken the last one
  
    // Ensure the node addresses were added to list of join request nodes
    let cHead1joinRequestNodes = cHead1.joinRequestNodes;
    let node1_0 = toStruct(await networkFormation.getNodeAsMemory(cHead1joinRequestNodes[0]));
    let node1_1 = toStruct(await networkFormation.getNodeAsMemory(cHead1joinRequestNodes[1]));
    assert.equal(node1_0.nodeAddress, 222012);
    assert.equal(node1_1.nodeAddress, 222013);
  
    let cHead2joinRequestNodes = cHead2.joinRequestNodes;
    let node2_0 = toStruct(await networkFormation.getNodeAsMemory(cHead2joinRequestNodes[0]));
    let node2_1 = toStruct(await networkFormation.getNodeAsMemory(cHead2joinRequestNodes[1]));
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
    await networkFormation.identifyBackupClusterHeads();
    
    console.log("::::: NODE 222002! :::::");
    let node222002 = toStruct(await networkFormation.getNodeAsMemory(222002));
    assert.equal(node222002.backupCHeads[0], 222001);
    assert.equal(node222002.backupCHeads[1], 222003);
    console.log("::::: NODE 222004! :::::");
    let node222004 = toStruct(await networkFormation.getNodeAsMemory(222004));
    assert.equal(node222004.backupCHeads[0], 222003);
    assert.equal(node222004.backupCHeads[1], 222005);
    console.log("::::: NODE 222007! :::::");
    let node222007 = toStruct(await networkFormation.getNodeAsMemory(222007));
    assert.equal(node222007.backupCHeads[0], 222003);
  });
  
  it("should elect cluster heads for Layer 3 nodes", async () => {
    // 50% chance of cluster head being elected
    await networkFormation.electClusterHeads(222006, 50);
    await networkFormation.electClusterHeads(222008, 50);
    await networkFormation.electClusterHeads(222009, 50);
  
    // Get the prospective child nodes
    let node6_12 = toStruct(await networkFormation.getNodeAsMemory(222012));
    let node6_13 = toStruct(await networkFormation.getNodeAsMemory(222013));    
    let node8_14 = toStruct(await networkFormation.getNodeAsMemory(222014));
    let node8_15 = toStruct(await networkFormation.getNodeAsMemory(222015));
  
    assert.equal(node6_13.nodeType, NodeType.ClusterHead);
    assert.equal(node8_15.nodeType, NodeType.ClusterHead);
  
    assert.equal(node6_12.nodeType, NodeType.MemberNode);
    assert.equal(node8_14.nodeType, NodeType.MemberNode);
    
  });
  
  it("should send sensor readings to sink node", async () => {
    // Simulate reading values from each sensor node
    await networkFormation.readSensorInput(9001, 222001);
    await networkFormation.readSensorInput(9002, 222002);
    await networkFormation.readSensorInput(9003, 222003);
    await networkFormation.readSensorInput(9004, 222004);
    await networkFormation.readSensorInput(9005, 222005);
    await networkFormation.readSensorInput(9006, 222006);
    await networkFormation.readSensorInput(9007, 222007);
    await networkFormation.readSensorInput(9008, 222008);
    await networkFormation.readSensorInput(9009, 222009);
    await networkFormation.readSensorInput(9010, 222010);
    await networkFormation.readSensorInput(9011, 222011);
    await networkFormation.readSensorInput(9012, 222012);
    await networkFormation.readSensorInput(9013, 222013);
    await networkFormation.readSensorInput(9014, 222014);
    await networkFormation.readSensorInput(9015, 222015);

    let node111000 = toStruct(await networkFormation.getNodeAsMemory(111000));
    let node222001 = toStruct(await networkFormation.getNodeAsMemory(222001));
    let node222002 = toStruct(await networkFormation.getNodeAsMemory(222002));
    let node222003 = toStruct(await networkFormation.getNodeAsMemory(222003));
    let node222004 = toStruct(await networkFormation.getNodeAsMemory(222004));
    let node222005 = toStruct(await networkFormation.getNodeAsMemory(222005));
    let node222006 = toStruct(await networkFormation.getNodeAsMemory(222006));
    let node222007 = toStruct(await networkFormation.getNodeAsMemory(222007));
    let node222008 = toStruct(await networkFormation.getNodeAsMemory(222008));
    let node222009 = toStruct(await networkFormation.getNodeAsMemory(222009));
    let node222010 = toStruct(await networkFormation.getNodeAsMemory(222010));
    let node222011 = toStruct(await networkFormation.getNodeAsMemory(222011));
    let node222012 = toStruct(await networkFormation.getNodeAsMemory(222012));
    let node222013 = toStruct(await networkFormation.getNodeAsMemory(222013));
    let node222014 = toStruct(await networkFormation.getNodeAsMemory(222014));
    let node222015 = toStruct(await networkFormation.getNodeAsMemory(222015));
  
    // Check that all sensor nodes got their readings
    // node: sensorReadings[0] is a dummy reading to help detect null values,
    assert.equal(node222001.sensorReadings[1].reading, 9001);
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
    assert.equal(node111000.sensorReadings[1].reading, 9001);
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

    // console.log((await networkFormation.getAllNodes()).map(node => toStruct(node)).map(function(nodeStruct) {
    //   return {
    //     nodeAddress: nodeStruct.nodeAddress, 
    //     backupCHeads: nodeStruct.backupCHeads
    //   };
    // }));
  });
  
  it("should be able to assign roles to nodes", async () => {
    await networkFormation.assignAsController(111000);
    await networkFormation.assignAsSensor(222001);
    await networkFormation.assignAsController(222002);
    await networkFormation.assignAsSensor(222003);
    await networkFormation.assignAsController(222004);
    await networkFormation.assignAsActuator(222005);
    await networkFormation.assignAsController(222006);
    await networkFormation.assignAsActuator(222007);
    await networkFormation.assignAsController(222008);
    await networkFormation.assignAsSensor(222009);
    await networkFormation.assignAsActuator(222010);
    await networkFormation.assignAsActuator(222011);
    await networkFormation.assignAsSensor(222012);
    await networkFormation.assignAsSensor(222013);
    await networkFormation.assignAsSensor(222014);
    await networkFormation.assignAsSensor(222015);

    let node111000 = toStruct(await networkFormation.getNodeAsMemory(111000));
    let node222001 = toStruct(await networkFormation.getNodeAsMemory(222001));
    let node222002 = toStruct(await networkFormation.getNodeAsMemory(222002));
    let node222003 = toStruct(await networkFormation.getNodeAsMemory(222003));
    let node222004 = toStruct(await networkFormation.getNodeAsMemory(222004));
    let node222005 = toStruct(await networkFormation.getNodeAsMemory(222005));
    let node222006 = toStruct(await networkFormation.getNodeAsMemory(222006));
    let node222007 = toStruct(await networkFormation.getNodeAsMemory(222007));
    let node222008 = toStruct(await networkFormation.getNodeAsMemory(222008));
    let node222009 = toStruct(await networkFormation.getNodeAsMemory(222009));
    let node222010 = toStruct(await networkFormation.getNodeAsMemory(222010));
    let node222011 = toStruct(await networkFormation.getNodeAsMemory(222011));
    let node222012 = toStruct(await networkFormation.getNodeAsMemory(222012));
    let node222013 = toStruct(await networkFormation.getNodeAsMemory(222013));
    let node222014 = toStruct(await networkFormation.getNodeAsMemory(222014));
    let node222015 = toStruct(await networkFormation.getNodeAsMemory(222015));

    assert.equal(node111000.nodeRole, NodeRole.Controller);
    assert.equal(node222001.nodeRole, NodeRole.Sensor);
    assert.equal(node222002.nodeRole, NodeRole.Controller);
    assert.equal(node222003.nodeRole, NodeRole.Sensor);
    assert.equal(node222004.nodeRole, NodeRole.Controller);
    assert.equal(node222005.nodeRole, NodeRole.Actuator);
    assert.equal(node222006.nodeRole, NodeRole.Controller);
    assert.equal(node222007.nodeRole, NodeRole.Actuator);
    assert.equal(node222008.nodeRole, NodeRole.Controller);
    assert.equal(node222009.nodeRole, NodeRole.Sensor);
    assert.equal(node222010.nodeRole, NodeRole.Actuator);
    assert.equal(node222011.nodeRole, NodeRole.Actuator);
    assert.equal(node222012.nodeRole, NodeRole.Sensor);
    assert.equal(node222013.nodeRole, NodeRole.Sensor);
    assert.equal(node222014.nodeRole, NodeRole.Sensor);
    assert.equal(node222015.nodeRole, NodeRole.Sensor);
    
    (await networkFormation.getAllNodes()).map(
      function(node) {
        console.log(toReadableString(node)); 
      }
    );

  });
  
  it("should be able to send reading to sink node even if its cluster head has become inactive", async () => {
    // Disable node 222002
    await networkFormation.deactivateNode(222002);
    
    // Send sensor reading from node 222007
    await networkFormation.readSensorInput(700700, 222007);

    let node111000 = toStruct(await networkFormation.getNodeAsMemory(111000));
    let node222002 = toStruct(await networkFormation.getNodeAsMemory(222002));
    let node222003 = toStruct(await networkFormation.getNodeAsMemory(222003));
    let node222004 = toStruct(await networkFormation.getNodeAsMemory(222004));
    let node222007 = toStruct(await networkFormation.getNodeAsMemory(222007));

    // console.log((await networkFormation.getAllNodes()).map(node => toStruct(node)).map(function(nodeStruct) {
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
