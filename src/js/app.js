import { NodeType } from "./solidity_enums.js";

function toNodeType(enumVal) {
  // need to convert the BigNumber returned by Solidity into a JS number
  switch (enumVal.toNumber()) {
    case NodeType.Unassigned: return "Unassigned";
    case NodeType.MemberNode: return "MemberNode";
    case NodeType.ClusterHead: return "ClusterHead";
    default: return "default";
  }
}

function toNodeRole(enumVal) {
  // need to convert the BigNumber returned by Solidity into a JS number
  switch (enumVal.toNumber()) {
    case NodeRole.Default: return "Default";
    case NodeRole.Sensor: return "Sensor";
    case NodeRole.Actuator: return "Actuator";
    case NodeRole.Controller: return "Controller";
    default: return "default";
  }
}

export const App = {
  web3Provider: null,
  contracts: {},

  //////////////////////////////////////////////////
  // INIT()
  //////////////////////////////////////////////////
  init: async function() {
    console.log("FLOW: init()");
    
    return await App.initWeb3();
  },

  //////////////////////////////////////////////////
  // INITWEB3()
  //////////////////////////////////////////////////
  initWeb3: async function() {
    console.log("FLOW: initWeb3()");

    // Modern dapp browsers...
    if (window.ethereum) {
      App.web3Provider = window.ethereum;
      try {
        // Request account access
        console.log("Waiting for account access");
        await window.ethereum.enable();
      } catch (error) {
        // User denied account access...
        console.error("User denied account access");
      }
    }
    // Legacy dapp browsers...
    else if (window.web3) {
      App.web3Provider = window.web3.currentProvider;
      console.log("Using a legacy dapp browser");
    }
    // If no injected web3 instance is detected, fall back to Ganache
    else {
      App.web3Provider = new Web3.providers.HttpProvider('http://localhost:7545');
      console.log("Using Ganache");
    }
    web3 = new Web3(App.web3Provider);

    return App.initContract();
  },

  //////////////////////////////////////////////////
  // INITCONTRACT()
  //////////////////////////////////////////////////
  initContract: function() {
    console.log("FLOW: initContract()");

    // change 'NetworkFormation' to the name of the future contract
    $.getJSON('NetworkFormation.json', function(data) {
      // Get the necessary contract artifact file and instantiate it with @truffle/contract
      var ContractArtifact = data;
      App.contracts.NetworkFormation = TruffleContract(ContractArtifact);

      // Set the provider for the contract
      App.contracts.NetworkFormation.setProvider(App.web3Provider);

      // Use our contract to initialise the data of this page
      return App.initialiseData();
    });
  },
  
  addNode: function(instance, nodeID, nodeAddr, nodeELevel, nodesWithinRange) {
    instance.addNode(nodeID, nodeAddr, nodeELevel, nodesWithinRange).then(function(result) {
      console.log("FLOW: adding more nodes - nodeID="+nodeID+" nodeAddr="+nodeAddr+" nodeELevel="+nodeELevel+" nodesWithinRange="+nodesWithinRange);
      $(".sensornode-box").append(`<div>
        <h2>Node ${result.logs[0].args.nodeID} with address ${result.logs[0].args.addr}</h2>
        <p>Energy level: ${result.logs[0].args.energyLevel}</p>
        <p>Network level: ${result.logs[0].args.networkLevel}</p>
        <p>isClusterHead: ${result.logs[0].args.isClusterHead}</p>
        <p>isMemberNode: ${result.logs[0].args.isMemberNode}</p>
        </div>`);
    }).catch(function(err) { 
      console.error("add more nodes ERROR! " + err.message);
    });
  },
  
  /* Adds data by inserting directly into the HTML with the following:
  <div>
    <h2>Node 10 with address 111000</h2>
    <p>Energy level: 22</p>
    <p>Network level: 22</p>
    <p>isClusterHead: true</p>
    <p>isMemberNode: true</p>
  </div>
  */
  initialiseData: function() {
    console.log("FLOW: initialiseData()");
    
    App.contracts.NetworkFormation.deployed().then(function(instance) {
      instance.numOfNodes().then(function(numOfNodes) {
        
        // Add a bunch of sample nodes if the number of nodes is 0
        if (numOfNodes == 0) {
          // Add the sink node (1 of many to come)
          App.addNode(instance, 10, 111000, 100, [222001, 222002, 222003, 222004, 222005]);
          
          // Add the child nodes
          App.addNode(instance, 11, 222001, 35, [111000, 222002]);
          App.addNode(instance, 12, 222002, 66, [111000, 222001, 222003]);
          App.addNode(instance, 13, 222003, 53, [111000, 222002, 222004]);
          App.addNode(instance, 14, 222004, 82, [111000, 222003, 222005]);
          App.addNode(instance, 15, 222005, 65, [111000, 222004]);
          
        }
        // Otherwise, load the existing sensor nodes
        else {
          instance.getAllNodeAddresses().then(function(result) {
            for (var i = 0; i < numOfNodes; i++) {
              console.log(i);
              console.log(result[i]);
              // gets all nodes and displays them
              instance.getNodeInfo(result[i]).then(function(data) {
                // Add colour coding to node background.
                // Cyan = cluster head.
                // Yellow = member node.
                // Red = unassigned node.
                var isClusterHead = (data[4] == NodeType.ClusterHead);
                var isMemberNode = (data[4] == NodeType.MemberNode);
                var isActive = data[6];
                var chosenStyle = (isClusterHead) ? "node-clusterhead" :
                    (isMemberNode) ? "node-membernode" : 
                    "node-unassigned";
                var chosenTextStyle = (isActive) ? "node-active" :
                    "node-inactive";
                var buttonLabel = (isActive) ? "Deactivate" :
                    "Activate";
                var buttonFunc = (isActive) ? "deactivateNode" :
                    "activateNode";

                $(".sensornode-box").append(`<div class="node-description ${chosenStyle} ${chosenTextStyle}">
                  <h2>Node ${data[0]} with address ${data[1]}</h2>
                  <p>Energy level: ${data[2]}</p>
                  <p>Network level: ${data[3]}</p>
                  <p>Node type: ${toNodeType(data[4])}</p>
                  <p>Sensor readings: [${data[5]}]</p>
                  <div class="input-group">
                    <label for="id-input-setactive">isActive: ${data[6]}</label>
                    <button class="btn btn-primary" onclick="App.${buttonFunc}(${data[1]})" id="btn2-${data[1]}">${buttonLabel}</button>
                  </div>
                  <p>Parent node: ${data[7]}</p>
                  <p>Nodes within range: [${data[8]}]</p>
                  <p>Backup cluster heads: [${data[9]}]</p>
                  <div class="input-group">
                    <label for="id-input-sreading">Add sensor reading: </label>
                    <input type="string" class="form-control" id="id-input-sreading-${data[0]}" placeholder="">
                  </div>
                  <button class="btn btn-primary" onclick="App.readSensorInput(${data[0]}, ${data[1]})" id="btn-${data[1]}">Simulate sensor reading</button>
                  </div>
                  <p>Node role: ${data[10]}</p>`)
              }).catch(function(err) {
                console.error("getting node ERROR! " + err.message)
              });
            }
          }).catch(function(err) {
            console.error("get all nodes ERROR! " + err.message);
          });
        }
        
      }).catch(function(err) {
        console.error("numOfNodes ERROR! " + err.message)
      });
      
    }).catch(function(err) { 
      console.error("ERROR! " + err.message)
    });
  },
  
  
  // Carry out the process to elect cluster heads
  registerAsClusterHead: function() {
    console.log("FLOW: electClusterHeads()");
    // Call the smart contract functions
    App.contracts.NetworkFormation.deployed().then(function(instance) {
      instance.registerAsClusterHead(0, 111000).then(function(result) {
        console.log("FLOW: registerAsClusterHead()");
      }).catch(function(err) {
        console.error("registerAsClusterHead ERROR! " + err.message)
      });
    }).catch(function(err) {
      console.error("NetworkFormation.deployed() ERROR! " + err.message)
    });
  },
  
  sendBeacon: function() {
    console.log("FLOW: sendBeacon()");
    // Call the smart contract functions
    App.contracts.NetworkFormation.deployed().then(function(instance) {
      instance.sendBeacon(111000).then(function(result) {
        console.log("FLOW: sendBeacon()");
      }).catch(function(err) {
        console.error("sendBeacon ERROR! " + err.message)
      });
    }).catch(function(err) {
      console.error("NetworkFormation.deployed() ERROR! " + err.message)
    });
  },
  
  sendJoinRequests: function() {
    console.log("FLOW: sendJoinRequests()");
    // Call the smart contract functions
    App.contracts.NetworkFormation.deployed().then(function(instance) {
      instance.sendJoinRequests().then(function(result) {
        console.log("FLOW: sendJoinRequests()");
      }).catch(function(err) {
        console.error("sendJoinRequests ERROR! " + err.message)
      });
    }).catch(function(err) {
      console.error("NetworkFormation.deployed() ERROR! " + err.message)
    });
  },
  
  electClusterHeads: function() {
    console.log("FLOW: electClusterHeads()");
    // Call the smart contract functions
    App.contracts.NetworkFormation.deployed().then(function(instance) {
      instance.electClusterHeads(111000, 65).then(function(result) {
        console.log("FLOW: electClusterHeads()");
      }).catch(function(err) {
        console.error("electClusterHeads ERROR! " + err.message)
      });
    }).catch(function(err) {
      console.error("NetworkFormation.deployed() ERROR! " + err.message)
    });
  },
  
  addNewNode: function() {
    console.log("FLOW: addNewNode()");

    // Get integer user input
    var nodeID = $("#id-input-id").val();
    var nodeAddr = $("#id-input-addr").val();
    var nodeELevel = $("#id-input-elevel").val();

    // Get array user input
    var nodeWRNodes = $("#id-input-wrnodes").val()
        .split(",").map(function (str) {  return parseInt(str); });

    $(".msg").html("<p>nodeID="+nodeID+" nodeAddr="+nodeAddr+" nodeELevel="+nodeELevel+" nodeWRNodes="+nodeWRNodes+"</p>");

    console.log(nodeWRNodes[0]);
    console.log(nodeWRNodes[1]);
    

    // Application Logic 
    // if (uid == "") {
    //   $(".msg").html("<p>Please enter id.</p>");
    //   return;
    // }
    
    
    // Call the smart contract function
    App.contracts.NetworkFormation.deployed().then(function(instance) {
      instance.addNode(nodeID, nodeAddr, nodeELevel, nodeWRNodes).then(function(result) {
        $(".msg").html("<p>Node added successfully.</p>");
      })
    }).catch(function(err) {
      console.error("addNode ERROR! " + err.message)
    });
  },

  readSensorInput: function(nodeID, nodeAddr) {
    console.log("FLOW: readSensorInput()");

    // Get integer user input
    var sReading = $("#id-input-sreading-" + nodeID).val();
    
    $(".msg").html("<p>sReading="+sReading+"</p>");
    console.log("sReading = " + sReading);
    console.log("nodeAddr = " + nodeAddr);

    // Application Logic 
    if (sReading == "") {
      $(".msg").html("<p>Please enter id.</p>");
      return;
    }
    
    // Call the smart contract function
    App.contracts.NetworkFormation.deployed().then(function(instance) {
      instance.readSensorInput(sReading, nodeAddr).then(function(result) {
        $(".msg").html("<p>Sensor reading simulated successfully.</p>");
      })
    }).catch(function(err) {
      console.error("readSensorInput ERROR! " + err.message)
    });
  },

  identifyBackupClusterHeads: function() {
    console.log("FLOW: identifyBackupClusterHeads()");

    // Call the smart contract function
    App.contracts.NetworkFormation.deployed().then(function(instance) {
      instance.identifyBackupClusterHeads().then(function(result) {
        console.log("Backup cluster heads for all nodes were identified.");
      })
    }).catch(function(err) {
      console.error("identifyBackupClusterHeads ERROR! " + err.message)
    });
  },

  deactivateNode: function(nodeAddr) {
    console.log("FLOW: deactivateNode()");

    // Call the smart contract function
    App.contracts.NetworkFormation.deployed().then(function(instance) {
      instance.deactivateNode(nodeAddr).then(function(result) {
        console.log("Node " + nodeAddr + " was deactivated.");
      })
    }).catch(function(err) {
      console.error("deactivateNode ERROR! " + err.message)
    });
  },

  activateNode: function(nodeAddr) {
    console.log("FLOW: activateNode()");

    // Call the smart contract function
    App.contracts.NetworkFormation.deployed().then(function(instance) {
      instance.activateNode(nodeAddr).then(function(result) {
        console.log("Node " + nodeAddr + " was REactivated.");
      })
    }).catch(function(err) {
      console.error("activateNode ERROR! " + err.message)
    });
  }
};

$(function() {
  $(window).load(function() {
    App.init();
  });
});
