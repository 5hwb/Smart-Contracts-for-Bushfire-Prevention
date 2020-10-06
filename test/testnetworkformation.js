// tutorials:
// * https://www.trufflesuite.com/docs/truffle/testing/writing-tests-in-javascript
// * https://kalis.me/assert-reverts-solidity-smart-contract-test-truffle/
// * https://ethereum.stackexchange.com/questions/48627/how-to-catch-revert-error-in-truffle-test-javascript#48629

// Contract abstractions provided by Truffle
// (TruffleContract instances)
const NetworkFormation = artifacts.require("NetworkFormation");
const NetworkFormation2 = artifacts.require("NetworkFormation2");
const SensorNode = artifacts.require("SensorNode");
const QuickSortContract = artifacts.require("QuickSortContract");

// Required for some test cases
const truffleAssert = require('truffle-assertions');

// NodeType enum values 
const NodeType = {
  Unassigned: 0,
  MemberNode: 1,
  ClusterHead: 2
};

// Convert the raw array returned by NetworkFormation into a Node struct format
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
    
    // TODO: add a new version for the NetworkFormation2 data
  };
}

contract("NetworkFormation test cases", async accounts => {
  let networkFormation;
  let networkFormation2;
  let sensorNode;
  
  beforeEach(async () => {
    networkFormation = await NetworkFormation.deployed();
    networkFormation2 = await NetworkFormation2.deployed();
    sensorNode = await SensorNode.deployed();
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
    // Add the 'sink node'
    await networkFormation.addNode(111000, 100, [222001, 222002, 222003, 222004, 222005]);

    // Add neighbouring nodes
    await networkFormation.addNode(222001, 35, [111000, 222002]);
    await networkFormation.addNode(222002, 66, [111000, 222001, 222003]);
    await networkFormation.addNode(222003, 53, [111000, 222002, 222004]);
    await networkFormation.addNode(222004, 82, [111000, 222003, 222005]);
    await networkFormation.addNode(222005, 65, [111000, 222004]);
    
    // Ensure there are 6 nodes
    assert.equal(await networkFormation.numOfNodes.call(), 6, "Num of nodes is not 6!");
    
    //console.log(toStruct(await networkFormation.getNodeAsMemory(111000)));
    
    // Ensure the values within the first DS.Node are as expected
    let firstNode = toStruct(await networkFormation.getNodeAt.call(0));
    let firstNodeAddr = firstNode.nodeAddress;
    let firstNodeEnergyLevel = firstNode.energyLevel;
    assert.equal(firstNodeAddr, 111000);
    assert.equal(firstNodeEnergyLevel, 100);
  });

  it("should send beacon", async () => {
    // Set sink node as the 1st cluster head
    await networkFormation.registerAsClusterHead(0, 111000);
  
    // Set its network level to be 0 (because sink node!)
    let sinkNode = await networkFormation.getNodeAsMemory(111000);

    // TODO move this to NetworkFormation - might add argument indicating if sink node or not
    //await networkFormation.setNetworkLevel(sinkNode, 0);
  
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
  
  it("should send join requests", async () => {
    // Make all nodes within range send a join request
    await networkFormation.sendJoinRequests();
    let sinkNode = toStruct(await networkFormation.getNodeAsMemory(111000));
  
    console.log("sinkNode = ");
    console.log(sinkNode);
  
    // Ensure the node addresses were added to list of join request nodes
    let node0 = toStruct(await networkFormation.getNodeAsMemory(sinkNode.links.joinRequestNodes[0]));
    let node1 = toStruct(await networkFormation.getNodeAsMemory(sinkNode.links.joinRequestNodes[1]));
    let node2 = toStruct(await networkFormation.getNodeAsMemory(sinkNode.links.joinRequestNodes[2]));
    let node3 = toStruct(await networkFormation.getNodeAsMemory(sinkNode.links.joinRequestNodes[3]));
    let node4 = toStruct(await networkFormation.getNodeAsMemory(sinkNode.links.joinRequestNodes[4]));
    assert.equal(node0.nodeAddress, 222001);
    assert.equal(node1.nodeAddress, 222002);
    assert.equal(node2.nodeAddress, 222003);
    assert.equal(node3.nodeAddress, 222004);
    assert.equal(node4.nodeAddress, 222005);
  });
  
  it("should elect cluster heads", async () => {
    // 40% chance of being elected?
    await networkFormation.electClusterHeads(111000, 40);
  
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
  
  it("should send sensor readings to sink node", async () => {
    // Simulate reading values from each sensor node
    await networkFormation.readSensorInput(9001, 222001);
    await networkFormation.readSensorInput(9002, 222002);
    await networkFormation.readSensorInput(9003, 222003);
    await networkFormation.readSensorInput(9004, 222004);
    await networkFormation.readSensorInput(9005, 222005);
  
    let node222001 = toStruct(await networkFormation.getNodeAsMemory(222001));
    let node222002 = toStruct(await networkFormation.getNodeAsMemory(222002));
    let node222003 = toStruct(await networkFormation.getNodeAsMemory(222003));
    let node222004 = toStruct(await networkFormation.getNodeAsMemory(222004));
    let node222005 = toStruct(await networkFormation.getNodeAsMemory(222005));
    let node111000 = toStruct(await networkFormation.getNodeAsMemory(111000));
  
    // Check that the sensor nodes got their readings
    // node: sensorReadings[0] is a dummy reading to help detect null values,
    // hence the 2nd element is actually the 1st reading
    assert.equal(node222001.sensorReadings[1].reading, 9001);
    assert.equal(node222002.sensorReadings[1].reading, 9002);
    assert.equal(node222003.sensorReadings[1].reading, 9003);
    assert.equal(node222004.sensorReadings[1].reading, 9004);
    assert.equal(node222005.sensorReadings[1].reading, 9005);
    
    // Check that the cluster head had received the sensor readings
    assert.equal(node111000.sensorReadings[1].reading, 9001);
    assert.equal(node111000.sensorReadings[2].reading, 9002);
    assert.equal(node111000.sensorReadings[3].reading, 9003);
    assert.equal(node111000.sensorReadings[4].reading, 9004);
    assert.equal(node111000.sensorReadings[5].reading, 9005);
  });

  it("should send sensor readings to sink node", async () => {
    console.log("addressOfNF2() = ");
    console.log(await networkFormation.addressOfNF2.call());
    
    assert.equal(await networkFormation2.numOfNodeRoleEntries.call(), 6);
    console.log("networkFormation2.getNodeRoleStuffAsMemory(111000) = ");
    console.log(await networkFormation2.getNodeRoleStuffAsMemory(111000));    
  });
  
  /***********************************************
   * TEST - Sorting SensorNode instances
   ***********************************************/
  it("should sort a SensorNode array", async () => {
  
    // sort to [89, 71, 62, 53]
    let sortedThingo = await networkFormation.getSortedNodes.call();
    let node0 = sortedThingo[0];
    let node1 = sortedThingo[1];
    let node2 = sortedThingo[2];
    let node3 = sortedThingo[3];
    let node4 = sortedThingo[4];
    let node5 = sortedThingo[5];
  
    // Check that nodes have been sorted by their energy levels in descending order
    assert.equal(node0.energyLevel, 100, "Sorting error");
    assert.equal(node1.energyLevel, 82, "Sorting error");
    assert.equal(node2.energyLevel, 66, "Sorting error");
    assert.equal(node3.energyLevel, 65, "Sorting error");
    assert.equal(node4.energyLevel, 53, "Sorting error");
    assert.equal(node5.energyLevel, 35, "Sorting error");
    // Another check to ensure the IDs are correct
    assert.equal(node0.nodeAddress, 111000, "Sorting error - wrong ID");
    assert.equal(node1.nodeAddress, 222004, "Sorting error - wrong ID");
    assert.equal(node2.nodeAddress, 222002, "Sorting error - wrong ID");
    assert.equal(node3.nodeAddress, 222005, "Sorting error - wrong ID");
    assert.equal(node4.nodeAddress, 222003, "Sorting error - wrong ID");
    assert.equal(node5.nodeAddress, 222001, "Sorting error - wrong ID");
  });
  
  /***********************************************
   * TEST - Sorting integers
   ***********************************************/
  it("should sort an int array", async () => {
    //let numCandidates = await networkFormation.numCandidates();
    //assert.equal(numVoters.toNumber(), 0);
    let sortInstance = await QuickSortContract.deployed();
    let thingo = [9, 2, 73, 3, 6, 2, 29];
    // sort to [2, 2, 3, 6, 9, 29, 73]
    let sortedThingo = await sortInstance.sortInts.call(thingo);
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
    //let numCandidates = await networkFormation.numCandidates();
    //assert.equal(numVoters.toNumber(), 0);
    let sortInstance = await QuickSortContract.deployed();
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
