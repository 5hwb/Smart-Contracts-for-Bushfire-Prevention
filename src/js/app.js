App = {
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
        
        if (numOfNodes == 0) {
          // Add the sink node (1 of many to come)
          instance.addNode(10, 111000, 100, [222001, 222002, 222003, 222004, 222005]).then(function(result) {
            console.log("FLOW: adding 1st node"); 
            $(".sensornode-box").append(`<div><h2>Node ${result.logs[0].args.nodeID} with address ${result.logs[0].args.addr}</h2><p>Energy level: ${result.logs[0].args.energyLevel}</p><p>Network level: ${result.logs[0].args.networkLevel}</p><p>isClusterHead: ${result.logs[0].args.isClusterHead}</p><p>isMemberNode: ${result.logs[0].args.isMemberNode}</p></div>`);
          }).catch(function(err) { 
            console.error("add 1st node ERROR! " + err.message);
          });
          
          // Add the child nodes
          instance.addNode(11, 222001, 35, [111000, 222002]).then(function(result) {
            console.log("FLOW: adding more nodes"); 
          }).catch(function(err) { 
            console.error("add more nodes ERROR! " + err.message);
          });
          instance.addNode(12, 222002, 66, [111000, 222001, 222003]).then(function(result) {
            console.log("FLOW: adding more nodes"); 
          }).catch(function(err) { 
            console.error("add more nodes ERROR! " + err.message);
          });
          instance.addNode(13, 222003, 53, [111000, 222002, 222004]).then(function(result) {
            console.log("FLOW: adding more nodes"); 
          }).catch(function(err) { 
            console.error("add more nodes ERROR! " + err.message);
          });
          instance.addNode(14, 222004, 82, [111000, 222003, 222005]).then(function(result) {
            console.log("FLOW: adding more nodes"); 
          }).catch(function(err) { 
            console.error("add more nodes ERROR! " + err.message);
          });
          instance.addNode(15, 222005, 65, [111000, 222004]).then(function(result) {
            console.log("FLOW: adding more nodes"); 
          }).catch(function(err) { 
            console.error("add more nodes ERROR! " + err.message);
          });
          
        } else {
          instance.getAllNodeAddresses().then(function(result) {
            for (var i = 0; i < numOfNodes; i++) {
              console.log(i);
              console.log(result[i]);
              // TODO load all nodes!
              // gets candidates and displays them
              instance.getNodeInfo(result[i]).then(function(data) {
                $(".sensornode-box").append(`<div><h2>Node ${data[0]} with address ${data[1]}</h2><p>Energy level: ${data[2]}</p><p>Network level: ${data[3]}</p><p>isClusterHead: ${data[4]}</p><p>isMemberNode: ${data[5]}</p></div>`)
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
  
  
  // function for testing only
  testo: function() {
    console.log("FLOW: testo()");

    var uid = $("#id-input").val(); // getting user inputted id

    // Application Logic 
    if (uid == "") {
      $(".msg").html("<p>Please enter id.</p>");
      return;
    }
    
    /*
    // Call the smart contract function
    App.contracts.NetworkFormation.deployed().then(function(instance) {
      instance.voterHasVoted(uid).then(function(result) {
        var resultString = (result == true) ? "You have voted already!" : "You have not voted yet.";
        $(".msg2").html("<p>" + resultString + "</p>");
      })
    }).catch(function(err) {
      console.error("voterHasVoted ERROR! " + err.message)
    });
    */
  }
};

$(function() {
  $(window).load(function() {
    App.init();
  });
});
