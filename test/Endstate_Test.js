
var Protocol = artifacts.require("./Protocol.sol");
var IActor = artifacts.require("./IActor.sol");

let catchRevert = require("./exceptions.js").catchRevert;
let senderAccountNotRecognized = require("./exceptions.js").senderAccountNotRecognized;

contract("Endstate_Test", async function(accounts) {
	
    var TargetOwner = accounts[0];
	var MitigatorOwner = accounts[1];
	var listOfAddresses = "Network1,Network2";
	
	//OK
	it("No Proof - T completes,T refunded --> payment to T", async function() {

		var instance = await Protocol.new();
		var contractAddress = instance.address;
		
		await instance.init(MitigatorOwner,2,await web3.utils.toWei('2.0', "ether"),listOfAddresses, {from: TargetOwner});
		await instance.approve(true, {from: MitigatorOwner});
		
		var fundsTarget = await web3.eth.getBalance(TargetOwner);
		
		await instance.sendFunds({from: TargetOwner,value: await web3.utils.toWei('2.0', "ether")});	
		
		assert.equal(isAtMost(await web3.eth.getBalance(TargetOwner),subtraction(fundsTarget,await web3.utils.toWei('2.0', "ether"))),true, "Endstate Target Funding not correct");
		
		wait(3000);	
		
		await instance.uploadProof("I've done my job", {from: TargetOwner});	
		
		await instance.ratingByTarget(0, {from: TargetOwner});	
		
		assert.equal(isAtMost(await web3.eth.getBalance(TargetOwner),fundsTarget),true, "Endstate Target Funding not correct");
		assert.equal(await instance.getCurrentState(),6,"State is not complete");
		assert.equal(isAtMost( await web3.eth.getBalance(contractAddress),0),true, "Endstate Funding Contract not correct");
		
    });
	
	//OK	
	it("No proof - T selfish --> no payment", async function() {
		
		var instance = await Protocol.new();
		var contractAddress = instance.address;
		
		await instance.init(MitigatorOwner,2,await web3.utils.toWei('2.0', "ether"),listOfAddresses, {from: TargetOwner});
		await instance.approve(true, {from: MitigatorOwner});
		
		var fundsTarget = await web3.eth.getBalance(TargetOwner);
		
		await instance.sendFunds({from: TargetOwner,value: await web3.utils.toWei('2.0', "ether")});	
		
		assert.equal(isAtMost(await web3.eth.getBalance(TargetOwner),subtraction(fundsTarget,await web3.utils.toWei('2.0', "ether"))),true, "Endstate Target Funding not correct");
		
		wait(3000);	
		
		await instance.uploadProof("I've done my job", {from: TargetOwner});	
		
		await instance.ratingByTarget(1, {from: TargetOwner});
				
		assert.equal(await instance.getCurrentState(),7,"State is not abort");
		assert.equal(isAtMost( await web3.eth.getBalance(TargetOwner),subtraction(fundsTarget,await web3.utils.toWei('2.0', "ether"))),true, "Endstate Target Funding not correct");
		assert.equal(isAtMost( await web3.eth.getBalance(contractAddress),await web3.utils.toWei('2.0', "ether")),true, "Endstate Funding Contract not correct");
		
    });
	
	//OK
	it("With proof - M Completes, M rewarded --> payment to M", async function() {
		
		var instance = await Protocol.new();
		var contractAddress = instance.address;
		
		await instance.init(MitigatorOwner,2,await web3.utils.toWei('2.0', "ether"),listOfAddresses, {from: TargetOwner});
		await instance.approve(true, {from: MitigatorOwner});
		
		var fundsTarget = await web3.eth.getBalance(TargetOwner);
		var fundsContract = await web3.eth.getBalance(contractAddress);
		
		await instance.sendFunds({from: TargetOwner,value: await web3.utils.toWei('2.0', "ether")});	
		
		assert.equal(isAtMost(await web3.eth.getBalance(TargetOwner),subtraction(fundsTarget,await web3.utils.toWei('2.0', "ether"))),true, "Endstate Target Funding not correct");
		
		await instance.uploadProof("I've done my job", {from: MitigatorOwner});	
		
		await instance.ratingByTarget(2, {from: TargetOwner});	
		
		var fundsMitigator = await web3.eth.getBalance(MitigatorOwner);
		
		await instance.ratingByMitigator(2, {from: MitigatorOwner});
		
		assert.equal(isAtMost( await web3.eth.getBalance(TargetOwner),subtraction(fundsTarget,await web3.utils.toWei('2.0', "ether"))),true, "Endstate Funding Target not correct");
		assert.equal(isAtMost( await web3.eth.getBalance(MitigatorOwner),addition(fundsMitigator,await web3.utils.toWei('2.0', "ether"))),true, "Endstate Funding Mitigator not correct");
		assert.equal(isAtMost( await web3.eth.getBalance(contractAddress),0),true, "Endstate Funding Contract not correct");
		assert.equal(await instance.getCurrentState(),6,"State is not complete");
		
    });	
	
	//OK
	it("With proof - T satisfied, M selfish --> no payment", async function() {
		
		var instance = await Protocol.new();
		var contractAddress = instance.address;
		
		await instance.init(MitigatorOwner,2,await web3.utils.toWei('2.0', "ether"),listOfAddresses, {from: TargetOwner});
		await instance.approve(true, {from: MitigatorOwner});
		
		var fundsTarget = await web3.eth.getBalance(TargetOwner);
		var fundsContract = await web3.eth.getBalance(contractAddress);
		
		await instance.sendFunds({from: TargetOwner,value: await web3.utils.toWei('2.0', "ether")});	
		
		assert.equal(isAtMost(await web3.eth.getBalance(TargetOwner),subtraction(fundsTarget,await web3.utils.toWei('2.0', "ether"))),true, "Endstate Target Funding not correct");
		
		
		await instance.uploadProof("I've done my job", {from: MitigatorOwner});	
		await instance.ratingByTarget(2, {from: TargetOwner});	
		
		var fundsMitigator = await web3.eth.getBalance(MitigatorOwner);
		
		wait(3000); 
		
		await instance.ratingByMitigator(2, {from: MitigatorOwner});
				
		assert.equal(isAtMost( await web3.eth.getBalance(TargetOwner),subtraction(fundsTarget,await web3.utils.toWei('2.0', "ether"))),true, "Endstate Funding Target not correct");
		assert.equal(isAtMost( await web3.eth.getBalance(MitigatorOwner),fundsMitigator),true, "Endstate Funding Mitigator not correct");
		assert.equal(isAtMost( await web3.eth.getBalance(contractAddress),await web3.utils.toWei('2.0', "ether")),true, "Endstate Funding Contract not correct");
		assert.equal(await instance.getCurrentState(),7,"State is not abort");
		
    });	
	
	//OK
	it("With proof - T selfish, M rational --> payment to M", async function() {
		
		var instance = await Protocol.new();
		var contractAddress = instance.address;
				
		await instance.init(MitigatorOwner,2,await web3.utils.toWei('2.0', "ether"),listOfAddresses, {from: TargetOwner});
		await instance.approve(true, {from: MitigatorOwner});
		
		var fundsTarget = await web3.eth.getBalance(TargetOwner);
		var fundsContract = await web3.eth.getBalance(contractAddress);
		
		await instance.sendFunds({from: TargetOwner,value: await web3.utils.toWei('2.0', "ether")});	
		
		assert.equal(isAtMost(await web3.eth.getBalance(TargetOwner),subtraction(fundsTarget,await web3.utils.toWei('2.0', "ether"))),true, "Endstate Target Funding not correct");

		await instance.uploadProof("I've done my job", {from: MitigatorOwner});	
		
		wait(3000); 
		
		await instance.ratingByTarget(2, {from: MitigatorOwner});	
		
		var fundsMitigator = await web3.eth.getBalance(MitigatorOwner);
	
		await instance.ratingByMitigator(0, {from: MitigatorOwner});

		assert.equal(isAtMost( await web3.eth.getBalance(TargetOwner),subtraction(fundsTarget,await web3.utils.toWei('2.0', "ether"))),true, "Endstate Funding Target not correct");
		assert.equal(isAtMost( await web3.eth.getBalance(MitigatorOwner),addition(fundsMitigator,await web3.utils.toWei('2.0', "ether"))),true, "Endstate Funding Mitigator not correct");
		assert.equal(isAtMost( await web3.eth.getBalance(contractAddress),0),true, "Endstate Funding Contract not correct");
		assert.equal(await instance.getCurrentState(),6,"State is not complete");

    });	
	
	//OK
	it("With proof - T selfish, M selfish --> no payment", async function() {
		
		var instance = await Protocol.new();
		var contractAddress = instance.address;
		
		await instance.init(MitigatorOwner,2,await web3.utils.toWei('2.0', "ether"),listOfAddresses, {from: TargetOwner});
		await instance.approve(true, {from: MitigatorOwner});
		
		var fundsTarget = await web3.eth.getBalance(TargetOwner);
		var fundsContract = await web3.eth.getBalance(contractAddress);
		
		await instance.sendFunds({from: TargetOwner,value: await web3.utils.toWei('2.0', "ether")});	
		
		assert.equal(isAtMost(await web3.eth.getBalance(TargetOwner),subtraction(fundsTarget,await web3.utils.toWei('2.0', "ether"))),true, "Endstate Target Funding not correct");
	
		await instance.uploadProof("I've done my job", {from: MitigatorOwner});	
		
		wait(3000); 
		
		await instance.ratingByTarget(2, {from: MitigatorOwner});	
		
		var fundsMitigator = await web3.eth.getBalance(MitigatorOwner);
	
		wait(3000); 
		
		await instance.ratingByMitigator(2, {from: MitigatorOwner});	
		
		assert.equal(isAtMost( await web3.eth.getBalance(TargetOwner),subtraction(fundsTarget,await web3.utils.toWei('2.0', "ether"))),true, "Endstate Funding Target not correct");
		assert.equal(isAtMost( await web3.eth.getBalance(MitigatorOwner),fundsMitigator),true, "Endstate Funding Mitigator not correct");
		assert.equal(isAtMost( await web3.eth.getBalance(contractAddress),await web3.utils.toWei('2.0', "ether")),true, "Endstate Funding Contract not correct");
		assert.equal(await instance.getCurrentState(),7,"State is not abort");

    });
	
	//OK
	it("With proof - T dissatisfied, M rational --> no payment,escalation", async function() {
		
		var instance = await Protocol.new();
		var contractAddress = instance.address;
		
		await instance.init(MitigatorOwner,2,await web3.utils.toWei('2.0', "ether"),listOfAddresses, {from: TargetOwner});
		await instance.approve(true, {from: MitigatorOwner});
		
		var fundsTarget = await web3.eth.getBalance(TargetOwner);
		var fundsContract = await web3.eth.getBalance(contractAddress);
		
		await instance.sendFunds({from: TargetOwner,value: await web3.utils.toWei('2.0', "ether")});	
		
		assert.equal(isAtMost(await web3.eth.getBalance(TargetOwner),subtraction(fundsTarget,await web3.utils.toWei('2.0', "ether"))),true, "Endstate Target Funding not correct");
		
		await instance.uploadProof("I've done my job", {from: MitigatorOwner});	
		
		await instance.ratingByTarget(0, {from: TargetOwner});	
		
		var fundsMitigator = await web3.eth.getBalance(MitigatorOwner);
		
		await instance.ratingByMitigator(0, {from: MitigatorOwner});

		assert.equal(isAtMost( await web3.eth.getBalance(TargetOwner),subtraction(fundsTarget,await web3.utils.toWei('2.0', "ether"))),true, "Endstate Funding Target not correct");
		assert.equal(isAtMost( await web3.eth.getBalance(MitigatorOwner),fundsMitigator),true, "Endstate Funding Mitigator not correct");
		assert.equal(isAtMost( await web3.eth.getBalance(contractAddress),await web3.utils.toWei('2.0', "ether")),true, "Endstate Funding Contract not correct");
		assert.equal(await instance.getCurrentState(),8,"State is not escalation");
		
    });
	
	//OK
	it("With proof - T dissatisfied, M selfish --> payment to T", async function() {
		
		var instance = await Protocol.new();
		var contractAddress = instance.address;
		
		var contractAddress = contractAddress;
		
		await instance.init(MitigatorOwner,2,await web3.utils.toWei('2.0', "ether"),listOfAddresses, {from: TargetOwner});
		await instance.approve(true, {from: MitigatorOwner});
		
		var fundsTarget = await web3.eth.getBalance(TargetOwner);
		var fundsContract = await web3.eth.getBalance(contractAddress);
		
		await instance.sendFunds({from: TargetOwner,value: await web3.utils.toWei('2.0', "ether")});	
		
		assert.equal(isAtMost(await web3.eth.getBalance(TargetOwner),subtraction(fundsTarget,await web3.utils.toWei('2.0', "ether"))),true, "Endstate Target Funding not correct");

		await instance.uploadProof("I've done my job", {from: MitigatorOwner});	
		
		await instance.ratingByTarget(0, {from: TargetOwner});	
		
		var fundsMitigator = await web3.eth.getBalance(MitigatorOwner);
		
		wait(3000); 
		
		await instance.ratingByMitigator(0, {from: TargetOwner});	

		assert.equal(isAtMost( await web3.eth.getBalance(TargetOwner),fundsTarget),true, "Endstate Funding Target not correct");
		assert.equal(isAtMost( await web3.eth.getBalance(MitigatorOwner),fundsMitigator),true, "Endstate Funding Mitigator not correct");
		assert.equal(isAtMost( await web3.eth.getBalance(contractAddress),0),true, "Endstate Funding Contract not correct");
		assert.equal(await instance.getCurrentState(),6,"State is not complete");
	
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
function wait(ms){
   var start = new Date().getTime();
   var end = start;
   while(end < start + ms) {
     end = new Date().getTime();
  }
}