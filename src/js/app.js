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

    // change 'Voting' to the name of the future contract
    $.getJSON('Voting.json', function(data) {
      // Get the necessary contract artifact file and instantiate it with @truffle/contract
      var ContractArtifact = data;
      App.contracts.Voting = TruffleContract(ContractArtifact);

      // Set the provider for the contract
      App.contracts.Voting.setProvider(App.web3Provider);

      // Use our contract to initialise the data of this page
      return App.initialiseData();
    });
  },
  
  initialiseData: function() {
    console.log("FLOW: initialiseData()");
    
    App.contracts.Voting.deployed().then(function(instance) {
      
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
    App.contracts.Voting.deployed().then(function(instance) {
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
