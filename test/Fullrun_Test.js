
var Protocol = artifacts.require("./Protocol.sol");

let catchRevert = require("./exceptions.js").catchRevert;

contract("Full Run Test", async function(accounts) {
	
	
    var TargetOwner = accounts[0];
	var MitigatorOwner = accounts[1];
	var listOfAddresses = "Network1,Network2";
	var protocol;
	
	it("Instantiation", async function() {
		
		protocol = await Protocol.new();
 
		await protocol.init(MitigatorOwner,120,await web3.utils.toWei('2.0', "ether"),listOfAddresses, {from: TargetOwner});
			
		assert.equal(await protocol.getCurrentState(), 1, "State is wrong");
		assert.equal(await protocol.getListOfAddresses(), listOfAddresses, "List of addresses is wrong");

    });
	
	
	it("Approve", async function() {

		await protocol.approve(true, {from: MitigatorOwner});
		assert.equal(await protocol.getCurrentState(), 2, "State is wrong");

    });
	
	it("Send Funds", async function() {
		
		var fundsTarget = await web3.eth.getBalance(TargetOwner);
		
		await protocol.sendFunds({from: TargetOwner,value: await web3.utils.toWei('2.0', "ether")});	
		assert.equal(await protocol.getCurrentState(), 3, "State is wrong");
		assert.equal(await web3.eth.getBalance(protocol.address), await web3.utils.toWei('2.0', "ether"), "Contract has wrong funds");
		assert.equal(isAtMost(await web3.eth.getBalance(TargetOwner),subtraction(fundsTarget,await web3.utils.toWei('2.0', "ether"))),true, "Funds not taken away from Target");
	
    });
	
	it("Upload Proof", async function() {
		
		await protocol.uploadProof("I've done my job", {from: MitigatorOwner});	
		assert.equal(await protocol.getCurrentState(), 4, "State is wrong");
		assert.equal(await protocol.getProof(), "I've done my job", "Proof is wrong");
    });
	
	it("Rate By Target", async function() {
	
		await protocol.ratingByTarget(2, {from: TargetOwner});	
		
		assert.equal(await protocol.getCurrentState(), 5, "State is wrong");
		assert.equal(await protocol.getTargetRating(), 2, "Proof is wrong");
		
    });
	
	it("Rate By Mitigator", async function() {
	
		var fundsMitigator = await web3.eth.getBalance(MitigatorOwner);
	
		await protocol.ratingByMitigator(2, {from: MitigatorOwner});
		
		assert.equal(await protocol.getCurrentState(), 6, "State is wrong");
		assert.equal(await protocol.getMitigatorRating(), 2, "Proof is wrong");
		assert.equal(isAtMost(await web3.eth.getBalance(protocol.address),0),true, "Funds not taken away from Contract");
		assert.equal(isAtMost(await web3.eth.getBalance(MitigatorOwner),addition(fundsMitigator,await web3.utils.toWei('2.0', "ether"))),true, "Funds not taken away from Target");

    });
	it("Time", async function() {
		
		console.log("StartTime: "+await protocol.getStartTime());
		console.log("EndTime: "+await protocol.getEndTime());
		console.log("Duration: "+subtraction(await protocol.getEndTime(),await protocol.getStartTime()));
    });
	
	
});

function isBiggerOrEqualThan(a,b){
	if(a>=b){
		return true;
	}	
	return false;
}

function addition(a,b){
	return parseInt(a)+parseInt(b);
}

function subtraction(a,b){
	return parseInt(a)-parseInt(b);
}


function isAtMost(a,b){
	if(a<=b){
		return true;
	}	
	return false;
}