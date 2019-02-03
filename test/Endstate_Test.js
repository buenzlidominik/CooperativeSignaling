
var Protocol = artifacts.require("./Protocol.sol");
var IActor = artifacts.require("./IActor.sol");
var ProcessData = artifacts.require("./ProcessData.sol");

let catchRevert = require("./exceptions.js").catchRevert;
let senderAccountNotRecognized = require("./exceptions.js").senderAccountNotRecognized;

contract("Endstate_Test", async function(accounts) {
	
	var protocol;
    var process;
	
    var TargetOwner = accounts[0];
	var MitigatorOwner = accounts[1];
	var MitigatorAddress;
	var TargetAddress;

    it("Mitigator Creation", async function() {
		return await Protocol.deployed().then(async function(instance) {          
			
			//Get the deployed protocol instance
			protocol = instance;
			
			var event = protocol.MitigatorCreated(function(error, response) {
				if (!error) {
					MitigatorAddress = response.args.addr;
				}else{
					console.log(error);
				}
			});

			//Define the fallback for the event which gives us the address of the created mitigator

			await protocol.registerMitigator(MitigatorOwner,1000,"Mitigator1", {from: TargetOwner});
			return await IActor.at(MitigatorAddress).then(async function(owner) { 
				assert.equal(MitigatorOwner, await owner.getOwner(), "Mitigator Address is wrong");
			});
		});
    });
		
	it("Target Creation", async function() {
			
		//Define the fallback for the event which gives us the address of the created mitigator
		var event = protocol.TargetCreated(function(error, response) {
			if (!error) {
				TargetAddress = response.args.addr;
			}else{
				console.log(error);
			}
		});
		await protocol.registerTarget(TargetOwner,1000,"Target1", {from: TargetOwner});
		return await IActor.at(TargetAddress).then(async function(owner) { 
			assert.equal(TargetOwner, await owner.getOwner(), "Target Address is wrong");
		});
    });
	
	it("No Proof - T completes,T refunded", async function() {

		var event = protocol.ProcessDataCreated(function(error, response) {
			if (!error) {
				process = response.args.addr;
			}else{
				console.log(error);
			}
		});
			
		var listOfAddresses = "Network1,Network2";

		var fundsMitigator = await web3.eth.getBalance(MitigatorOwner);
		var fundsTarget = await web3.eth.getBalance(TargetOwner);
		
		//This init is accepted
		await protocol.init(MitigatorAddress,2,2002,listOfAddresses,2, {from: TargetOwner});
		await protocol.approve(process,true, {from: MitigatorOwner});
		await protocol.sendFunds(process, {from: TargetOwner,value: 2002});	
		
		return await ProcessData.at(process).then(async function (result){
			assert.equal(isAtMost(await web3.eth.getBalance(TargetOwner),fundsTarget-2002),true, "Endstate Target Funding not correct");
		});
		
		wait(2000);	
		
		await protocol.skipCurrentState(process,{from: TargetOwner});
		await protocol.ratingByTarget(process,0, {from: TargetOwner});	
		
		return await ProcessData.at(process).then(async function (result){
			assert.equal(isAtMost(await web3.eth.getBalance(TargetOwner),fundsTarget),true, "Endstate Target Funding not correct");
		});
		
    });
	
	
	it("No proof - T selfish", async function() {
		
		var event = protocol.ProcessDataCreated(function(error, response) {
			if (!error) {
				process = response.args.addr;
			}else{
				console.log(error);
			}
		});
		
		var listOfAddresses = "Network1,Network2";

		var fundsMitigator = await web3.eth.getBalance(MitigatorOwner);
		var fundsTarget = await web3.eth.getBalance(TargetOwner);
		
		//This init is accepted
		await protocol.init(MitigatorAddress,2,2002,listOfAddresses,2, {from: TargetOwner});
		await protocol.approve(process,true, {from: MitigatorOwner});
		await protocol.sendFunds(process, {from: TargetOwner,value: 2002});	
		
		return await ProcessData.at(process).then(async function (result){
			assert.equal(isAtMost(await web3.eth.getBalance(TargetOwner),fundsTarget-2002),true, "Endstate Target Funding not correct");
		});
		
		wait(2000); 
		
		await protocol.skipCurrentState(process,{from: TargetOwner});
		await protocol.ratingByTarget(process,1, {from: TargetOwner});	
		
		return await ProcessData.at(process).then(async function (result){
			assert.equal(isAtMost( await web3.eth.getBalance(TargetOwner),fundsTarget-2002),true, "Endstate Target Funding not correct");
		});
		
    });
	
	it("With proof - M Completes, M rewarded", async function() {
		
		var event = protocol.ProcessDataCreated(function(error, response) {
			if (!error) {
				process = response.args.addr;
			}else{
				console.log(error);
			}
		});
		
		var listOfAddresses = "Network1,Network2";

		var fundsMitigator = await web3.eth.getBalance(MitigatorOwner);
		var fundsTarget = await web3.eth.getBalance(TargetOwner);
		
		//This init is accepted
		await protocol.init(MitigatorAddress,2,2002,listOfAddresses,2, {from: TargetOwner});
		await protocol.approve(process,true, {from: MitigatorOwner});
		await protocol.sendFunds(process, {from: TargetOwner,value: 2002});	
		
		return await ProcessData.at(process).then(async function (result){
			assert.equal(isAtMost(await web3.eth.getBalance(TargetOwner),fundsTarget-2002),true, "Endstate Target Funding not correct");
		});
		
		await protocol.uploadProof(process,"I've done my job", {from: MitigatorOwner});	
		await protocol.ratingByTarget(process,2, {from: TargetOwner});	
		await protocol.ratingByMitigator(process,2, {from: MitigatorOwner});
		
		return await ProcessData.at(process).then(async function (result){
			assert.equal(isAtMost( await web3.eth.getBalance(TargetOwner),fundsTarget-2002),true, "Endstate Funding Target not correct");
			assert.equal(isAtMost( await web3.eth.getBalance(MitigatorOwner),fundsMitigator+2002),true, "Endstate Funding Mitigator not correct");
		});
		
    });	
});

function isAtMost(a,b){
	if(a<=b){
		return true;
	}	
	return false;
}

function wait(ms){
   var start = new Date().getTime();
   var end = start;
   while(end < start + ms) {
     end = new Date().getTime();
  }
}