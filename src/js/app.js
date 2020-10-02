import { NodeType, NodeRole } from "./solidity_enums.js";

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
    
    // Set up buttons
    document.querySelector('#btn-addNewNode').addEventListener('click', App.addNewNode);
    document.querySelector('#btn-registerAsClusterHead').addEventListener('click', App.registerAsClusterHead);
    document.querySelector('#btn-sendBeacon').addEventListener('click', App.sendBeacon);
    document.querySelector('#btn-sendJoinRequests').addEventListener('click', App.sendJoinRequests);
    document.querySelector('#btn-electClusterHeads').addEventListener('click', App.electClusterHeads);
    document.querySelector('#btn-identifyBackupClusterHeads').addEventListener('click', App.identifyBackupClusterHeads);

    document.querySelector('#btn-runClusterHeadElection').addEventListener('click', App.runClusterHeadElection);
    
    document.querySelector('#btn-assignNodeAsSensor').addEventListener('click', App.assignNodeAsSensor);
    document.querySelector('#btn-assignNodeAsController').addEventListener('click', App.assignNodeAsController);
    document.querySelector('#btn-assignNodeAsActuator').addEventListener('click', App.assignNodeAsActuator);

    document.querySelector('#btn-respondToSensorInput').addEventListener('click', App.respondToSensorInput);

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
  
  addNode: function(instance, nodeAddr, nodeELevel, nodesWithinRange) {
    instance.addNode(nodeAddr, nodeELevel, nodesWithinRange).then(function(result) {
      console.log("FLOW: adding more nodes - nodeAddr="+nodeAddr+" nodeELevel="+nodeELevel+" nodesWithinRange="+nodesWithinRange);
      $(".sensornode-box").append(`<div>
        <h2>Node with address ${result.logs[0].args.addr}</h2>
        <p>Energy level: ${result.logs[0].args.energyLevel}</p>
        <p>Network level: ${result.logs[0].args.networkLevel}</p>
        <p>isClusterHead: ${result.logs[0].args.isClusterHead}</p>
        <p>isMemberNode: ${result.logs[0].args.isMemberNode}</p>
        </div>`);
    }).catch(function(err) { 
      console.error("add more nodes ERROR! " + err.message);
    });
  },
  
  loadNodeData: function(instance) {
    instance.getAllNodeAddresses().then(function(result) {
      for (var i = 0; i < result.length; i++) {
        console.log("==================================================");
        console.log(i);
        console.log(result[i]);
        
        var currentAddr = result[i];
        
        // gets all nodes and displays them
        instance.getNodeInfo(currentAddr).then(function(data) {
          console.log("currentAddr in gni: " + currentAddr);
          // Add colour coding to node background.
          // Cyan = cluster head.
          // Yellow = member node.
          // Red = unassigned node.
          var isClusterHead = (data[3] == NodeType.ClusterHead);
          var isMemberNode = (data[3] == NodeType.MemberNode);
          var chosenStyle = (isClusterHead) ? "node-clusterhead" :
              (isMemberNode) ? "node-membernode" : 
              "node-unassigned";
          
          var isActive = data[5];
          var chosenTextStyle = (isActive) ? "node-active" :
              "node-inactive";
          var buttonLabel = (isActive) ? "Deactivate" :
              "Activate";
          var buttonFunc = (isActive) ? "deactivateNode" :
              "activateNode";            

          var isTriggeringExternalService = data[6];
          var chosenBorderStyle = (isTriggeringExternalService) ? "node-triggeredactuator" : "";
          var actuatorMsgStyle = (isTriggeringExternalService) ? "node-msg-triggeredactuator" : "";            

          $(".sensornode-box").append(`<div class="node-description ${chosenStyle} ${chosenTextStyle} ${chosenBorderStyle}">
            <h2>Node with address ${data[0]}</h2>
            <p>Energy level: ${data[1]}</p>
            <p>Network level: ${data[2]}</p>
            <p>Node type: ${toNodeType(data[3])}</p>
            <p>Node role: ${toNodeRole(data[4])}</p>

            <div class="input-group">
              <label for="id-input-setactive">Is currently active: ${data[5]}</label>
              <button class="btn btn-primary" id="btn-${buttonFunc}-${data[0]}" id="btn2-${data[1]}">${buttonLabel}</button>
            </div>

            <p>Is triggering an external service: ${data[6]}</p>
            <p class="${actuatorMsgStyle}">Message: ${data[7]}</p>

            <p>Sensor readings: [${data[8]}]</p>
            <div class="input-group">
              <label for="id-input-sreading">Add sensor reading: </label>
              <input type="string" class="form-control" id="id-input-sreading-${data[0]}" placeholder="">
            </div>
            <button class="btn btn-primary" id="btn-readSensorInput-${data[0]}">Simulate sensor reading</button>
            </div>`);

          // Set event listener for 'De/Activate' button
          if (isActive) {
            console.log("Set deactivate node");
            document.querySelector("#btn-"+buttonFunc+"-"+data[0]).addEventListener('click', App.deactivateNode.bind(null, data[0]));              
          } else {
            console.log("Set ACTivate node");
            document.querySelector("#btn-"+buttonFunc+"-"+data[0]).addEventListener('click', App.activateNode.bind(null, data[1]));
          }
          
          // Set event listener for sensor reading simulation button
          document.querySelector("#btn-readSensorInput-"+data[0]).addEventListener('click', App.readSensorInput.bind(null, data[0]));              


        }).catch(function(err) {
          console.error("getNodeInfo ERROR! " + err.message);
        });
        
      }
    }).catch(function(err) {
      console.error("get all nodes ERROR! " + err.message);
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
          App.addNode(instance, 111000, 100, [222001, 222002, 222003, 222004, 222005]);
          
          // Add the child nodes
          App.addNode(instance, 222001, 35, [111000, 222002]);
          App.addNode(instance, 222002, 66, [111000, 222001, 222003]);
          App.addNode(instance, 222003, 53, [111000, 222002, 222004]);
          App.addNode(instance, 222004, 82, [111000, 222003, 222005]);
          App.addNode(instance, 222005, 65, [111000, 222004]);
          
        }
        // Otherwise, load the existing sensor nodes
        else {
          App.loadNodeData(instance);
        }
      });
    }).catch(function(err) { 
      console.error("numOfNodes ERROR! " + err.message);
    });
  },
  
  
  // Carry out the process to elect cluster heads
  registerAsClusterHead: function() {
    console.log("FLOW: electClusterHeads()");
    // Call the smart contract functions
    App.contracts.NetworkFormation.deployed().then(function(instance) {
      instance.registerAsClusterHead(0, 111000).then(function(result) {
        console.log("FLOW: registerAsClusterHead()");
      });
    }).catch(function(err) {
      console.error("registerAsClusterHead ERROR! " + err.message);
    });
  },
  
  sendBeacon: function() {
    console.log("FLOW: sendBeacon()");
    // Call the smart contract functions
    App.contracts.NetworkFormation.deployed().then(function(instance) {
      instance.sendBeacon(111000).then(function(result) {
        console.log("FLOW: sendBeacon()");
      });
    }).catch(function(err) {
      console.error("sendBeacon ERROR! " + err.message);
    });
  },
  
  sendJoinRequests: function() {
    console.log("FLOW: sendJoinRequests()");
    // Call the smart contract functions
    App.contracts.NetworkFormation.deployed().then(function(instance) {
      instance.sendJoinRequests().then(function(result) {
        console.log("FLOW: sendJoinRequests()");
      });
    }).catch(function(err) {
      console.error("sendJoinRequests ERROR! " + err.message);
    });
  },
  
  // basically runClusterHeadElection() but for the sink node only
  electClusterHeads: function() {
    console.log("FLOW: electClusterHeads()");
    // Call the smart contract functions
    App.contracts.NetworkFormation.deployed().then(function(instance) {
      instance.electClusterHeads(111000, 50).then(function(result) {
        console.log("FLOW: electClusterHeads() success");
      });
    }).catch(function(err) {
      console.error("electClusterHeads ERROR! " + err.message);
    });
  },
  
  runClusterHeadElection: function() {
    console.log("FLOW: runClusterHeadElection()");
    var nodeAddr = $("#id-input-runClusterHeadElection").val();
    
    // Call the smart contract functions
    App.contracts.NetworkFormation.deployed().then(function(instance) {
      instance.electClusterHeads(nodeAddr, 50).then(function(result) {
        console.log("FLOW: runClusterHeadElection() success");
      }).catch(function(err) {
        console.error("runClusterHeadElection ERROR! " + err.message);
      });
    }).catch(function(err) {
      console.error("NetworkFormation.deployed() ERROR! " + err.message);
    });
  },
  
  addNewNode: function() {
    console.log("FLOW: addNewNode()");

    // Get integer user input
    var nodeAddr = $("#id-input-addr").val();
    var nodeELevel = $("#id-input-elevel").val();

    // Get array user input
    var nodeWRNodes = $("#id-input-wrnodes").val()
        .split(",").map(function (str) {  return parseInt(str); });

    $(".msg").html("<p>nodeAddr="+nodeAddr+" nodeELevel="+nodeELevel+" nodeWRNodes="+nodeWRNodes+"</p>");

    console.log(nodeWRNodes[0]);
    console.log(nodeWRNodes[1]);
    

    // Application Logic 
    // if (uid == "") {
    //   $(".msg").html("<p>Please enter id.</p>");
    //   return;
    // }
    
    
    // Call the smart contract function
    App.contracts.NetworkFormation.deployed().then(function(instance) {
      instance.addNode(nodeAddr, nodeELevel, nodeWRNodes).then(function(result) {
        $(".msg").html("<p>Node added successfully.</p>");
      })
    }).catch(function(err) {
      console.error("addNode ERROR! " + err.message);
    });
  },

  readSensorInput: function(nodeAddr) {
    console.log("FLOW: readSensorInput(" + nodeAddr + ")");

    // Get integer user input
    var sReading = $("#id-input-sreading-" + nodeAddr).val();
    
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
      });
    }).catch(function(err) {
      console.error("readSensorInput ERROR! " + err.message);
    });
  },

  identifyBackupClusterHeads: function() {
    console.log("FLOW: identifyBackupClusterHeads()");

    // Call the smart contract function
    App.contracts.NetworkFormation.deployed().then(function(instance) {
      instance.identifyBackupClusterHeads().then(function(result) {
        console.log("Backup cluster heads for all nodes were identified.");
      });
    }).catch(function(err) {
      console.error("identifyBackupClusterHeads ERROR! " + err.message);
    });
  },

  deactivateNode: function(nodeAddr) {
    console.log("FLOW: deactivateNode(" + nodeAddr + ")");
    console.log(nodeAddr);

    // Call the smart contract function
    App.contracts.NetworkFormation.deployed().then(function(instance) {
      instance.deactivateNode(nodeAddr).then(function(result) {
        console.log("Node " + nodeAddr + " was deactivated.");
      });
    }).catch(function(err) {
      console.error("deactivateNode ERROR! " + err.message);
    });
  },

  activateNode: function(nodeAddr) {
    console.log("FLOW: activateNode(" + nodeAddr + ")");

    // Call the smart contract function
    App.contracts.NetworkFormation.deployed().then(function(instance) {
      instance.activateNode(nodeAddr).then(function(result) {
        console.log("Node " + nodeAddr + " was REactivated.");
      });
    }).catch(function(err) {
      console.error("activateNode ERROR! " + err.message);
    });
  },
  
  assignNodeAsSensor: function() {
    var nodeAddr = $("#id-input-assignNodeAsSensor").val();
    console.log("FLOW: assignNodeAsSensor() "+nodeAddr);

    // Call the smart contract functions
    App.contracts.NetworkFormation.deployed().then(function(instance) {
      instance.assignAsSensor(nodeAddr).then(function(result) {
        console.log("FLOW: assignNodeAsSensor() "+nodeAddr+" success");
      });
    }).catch(function(err) {
      console.error("assignNodeAsSensor ERROR! " + err.message);
    });
  },

  assignNodeAsController: function() {
    var nodeAddr = $("#id-input-assignNodeAsController").val();
    console.log("FLOW: assignNodeAsController() "+nodeAddr);

    // Call the smart contract functions
    App.contracts.NetworkFormation.deployed().then(function(instance) {
      instance.assignAsController(nodeAddr).then(function(result) {
        console.log("FLOW: assignNodeAsController() "+nodeAddr+" success");
      });
    }).catch(function(err) {
      console.error("assignNodeAsController ERROR! " + err.message);
    });
  },

  assignNodeAsActuator: function() {
    var nodeAddr = $("#id-input-assignNodeAsActuator-addr").val();
    var actuatorMsg = $("#id-input-assignNodeAsActuator-msg").val();
    console.log("FLOW: assignNodeAsActuator() "+nodeAddr+" '"+actuatorMsg+"'");

    // Call the smart contract functions
    App.contracts.NetworkFormation.deployed().then(function(instance) {
      instance.assignAsActuator(nodeAddr, actuatorMsg).then(function(result) {
        console.log("FLOW: assignNodeAsActuator("+nodeAddr+" '"+actuatorMsg+"' success");
      });
    }).catch(function(err) {
      console.error("assignNodeAsActuator ERROR! " + err.message);
    });
  },

  respondToSensorInput: function() {
    var nodeAddr = $("#id-input-respondToSensorInput").val();
    console.log("FLOW: respondToSensorInput() "+nodeAddr);

    // Call the smart contract functions
    App.contracts.NetworkFormation.deployed().then(function(instance) {
      instance.respondToSensorInput(nodeAddr).then(function(result) {
        console.log("FLOW: respondToSensorInput() "+nodeAddr+" success");
      });
    }).catch(function(err) {
      console.error("respondToSensorInput ERROR! " + err.message);
    });
  }
};



$(function() {
  $(window).load(function() {
    App.init();
  });
});
