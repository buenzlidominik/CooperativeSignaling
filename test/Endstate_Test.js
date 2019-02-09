
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
	var Address;
	var MitigatorAddress;
	var TargetAddress;
	
    it("Actor Creation", async function() {
        return await Protocol.deployed().then(async function(instance) {          
			//Get the deployed protocol instance
			protocol = instance;
			//Define the fallback for the event which gives us the address of the created mitigator
			var event = protocol.ActorCreated(function(error, response) {
				if (!error) {
					Address = response.args.addr;
				}else{
					console.log(error);
				}
			});
	
			await protocol.registerActor(MitigatorOwner,1000,"Mitigator1", {from: MitigatorOwner});
			MitigatorAddress = Address;
			await IActor.at(MitigatorAddress).then(async function(owner) { 
				assert.equal(MitigatorOwner, await owner.getOwner(), "Mitigator Address is wrong");
			});
			
			
			await protocol.registerActor(TargetOwner,1000,"Target1", {from: TargetOwner});
			TargetAddress = Address;
			return await IActor.at(TargetAddress).then(async function(owner) { 
				assert.equal(TargetOwner, await owner.getOwner(), "Target Address is wrong");
			});

		});
    });
	
	it("No Proof - T completes,T refunded --> payment to T", async function() {

		var event = protocol.ProcessDataCreated(function(error, response) {
			if (!error) {
				process = response.args.addr;
			}else{
				console.log(error);
			}
		});
			
		var listOfAddresses = "Network1,Network2";
		
		//This init is accepted
		await protocol.init(MitigatorOwner,2,2002,listOfAddresses,2, {from: TargetOwner});
		await protocol.approve(process,true, {from: MitigatorOwner});
		
		var fundsTarget = await web3.eth.getBalance(TargetOwner);
		
		await protocol.sendFunds(process, {from: TargetOwner,value: await web3.utils.toWei('2.0', "ether")});	
		
		await ProcessData.at(process).then(async function (result){
			assert.equal(isAtMost(await web3.eth.getBalance(TargetOwner),subtraction(fundsTarget,await web3.utils.toWei('2.0', "ether"))),true, "Endstate Target Funding not correct");
		});
		
		wait(3000);	
		
		await protocol.skipCurrentState(process,{from: TargetOwner});
		await protocol.ratingByTarget(process,0, {from: TargetOwner});	
		
		await ProcessData.at(process).then(async function (result){
			await result.getStartAndEndTime().then( async function (response){
				console.log("Starttime:"+ response[0])
				console.log("Endtime:"+ response[1]);
				assert.equal(isBiggerOrEqualThan(response[1],response[0]),true, "StartTime >= Endtime");
			});
		});	

		return await ProcessData.at(process).then(async function (result){
			assert.equal(isAtMost(await web3.eth.getBalance(TargetOwner),fundsTarget),true, "Endstate Target Funding not correct");
			assert.equal(await result.getState(),6,"State is not complete");
			assert.equal(isAtMost( await web3.eth.getBalance(process),0),true, "Endstate Funding Contract not correct");
		});
		
    });
	
	
	it("No proof - T selfish --> no payment", async function() {
		
		var event = protocol.ProcessDataCreated(function(error, response) {
			if (!error) {
				process = response.args.addr;
			}else{
				console.log(error);
			}
		});
		
		var listOfAddresses = "Network1,Network2";

		//This init is accepted
		await protocol.init(MitigatorOwner,2,2002,listOfAddresses,2, {from: TargetOwner});
		await protocol.approve(process,true, {from: MitigatorOwner});
		
		var fundsTarget = await web3.eth.getBalance(TargetOwner);
		
		await protocol.sendFunds(process, {from: TargetOwner,value: await web3.utils.toWei('2.0', "ether")});	
		
		await ProcessData.at(process).then(async function (result){
			assert.equal(isAtMost(await web3.eth.getBalance(TargetOwner),subtraction(fundsTarget,await web3.utils.toWei('2.0', "ether"))),true, "Target Funding not correct");
		});
		
		wait(3000); 
		
		await protocol.skipCurrentState(process,{from: TargetOwner});
	
		await protocol.ratingByTarget(process,1, {from: TargetOwner});	
		
		await ProcessData.at(process).then(async function (result){
			await result.getStartAndEndTime().then( async function (response){
				console.log("Starttime:"+ response[0])
				console.log("Endtime:"+ response[1]);
				assert.equal(isBiggerOrEqualThan(response[1],response[0]),true, "StartTime >= Endtime");
			});
		});	
		
		return await ProcessData.at(process).then(async function (result){
			assert.equal(await result.getState(),7,"State is not abort");
			assert.equal(isAtMost( await web3.eth.getBalance(TargetOwner),subtraction(fundsTarget,await web3.utils.toWei('2.0', "ether"))),true, "Endstate Target Funding not correct");
			assert.equal(isAtMost( await web3.eth.getBalance(process),await web3.utils.toWei('2.0', "ether")),true, "Endstate Funding Contract not correct");
		});
		
    });
	
	it("With proof - M Completes, M rewarded --> payment to M", async function() {
		
		var event = protocol.ProcessDataCreated(function(error, response) {
			if (!error) {
				process = response.args.addr;
			}else{
				console.log(error);
			}
		});

		var listOfAddresses = "Network1,Network2";
		
		//This init is accepted
		await protocol.init(MitigatorOwner,2,2002,listOfAddresses,2, {from: TargetOwner});
		await protocol.approve(process,true, {from: MitigatorOwner});
		
		var fundsTarget = await web3.eth.getBalance(TargetOwner);
		var fundsContract = await web3.eth.getBalance(process);
		
		await protocol.sendFunds(process, {from: TargetOwner,value: await web3.utils.toWei('2.0', "ether")});	
		
		await ProcessData.at(process).then(async function (result){
			assert.equal(isAtMost(await web3.eth.getBalance(TargetOwner),subtraction(fundsTarget,await web3.utils.toWei('2.0', "ether"))),true, "Endstate Target Funding not correct");
		});
		
		await protocol.uploadProof(process,"I've done my job", {from: MitigatorOwner});	
		await protocol.ratingByTarget(process,2, {from: TargetOwner});	
		
		var fundsMitigator = await web3.eth.getBalance(MitigatorOwner);
		
		await protocol.ratingByMitigator(process,2, {from: MitigatorOwner});
		
		await ProcessData.at(process).then(async function (result){
			await result.getStartAndEndTime().then( async function (response){
				console.log("Starttime:"+ response[0])
				console.log("Endtime:"+ response[1]);
				assert.equal(isBiggerOrEqualThan(response[1],response[0]),true, "StartTime >= Endtime");
			});
		});	
		
		return await ProcessData.at(process).then(async function (result){
		
			assert.equal(isAtMost( await web3.eth.getBalance(TargetOwner),subtraction(fundsTarget,await web3.utils.toWei('2.0', "ether"))),true, "Endstate Funding Target not correct");
			assert.equal(isAtMost( await web3.eth.getBalance(MitigatorOwner),addition(fundsMitigator,await web3.utils.toWei('2.0', "ether"))),true, "Endstate Funding Mitigator not correct");
			assert.equal(isAtMost( await web3.eth.getBalance(process),0),true, "Endstate Funding Contract not correct");
			assert.equal(await result.getState(),6,"State is not complete");
		});
    });	
	
	it("With proof - T satisfied, M selfish --> no payment", async function() {
		
		var event = protocol.ProcessDataCreated(function(error, response) {
			if (!error) {
				process = response.args.addr;
			}else{
				console.log(error);
			}
		});

		var listOfAddresses = "Network1,Network2";
		
		//This init is accepted
		await protocol.init(MitigatorOwner,2,2002,listOfAddresses,2, {from: TargetOwner});
		await protocol.approve(process,true, {from: MitigatorOwner});
		
		var fundsTarget = await web3.eth.getBalance(TargetOwner);
		var fundsContract = await web3.eth.getBalance(process);
		
		await protocol.sendFunds(process, {from: TargetOwner,value: await web3.utils.toWei('2.0', "ether")});	
		
		await ProcessData.at(process).then(async function (result){
			assert.equal(isAtMost(await web3.eth.getBalance(TargetOwner),subtraction(fundsTarget,await web3.utils.toWei('2.0', "ether"))),true, "Endstate Target Funding not correct");
		});
		
		await protocol.uploadProof(process,"I've done my job", {from: MitigatorOwner});	
		await protocol.ratingByTarget(process,2, {from: TargetOwner});	
		
		var fundsMitigator = await web3.eth.getBalance(MitigatorOwner);
		
		wait(3000); 
		
		await protocol.skipCurrentState(process,{from: TargetOwner});
		
		await ProcessData.at(process).then(async function (result){
			await result.getStartAndEndTime().then( async function (response){
				console.log("Starttime:"+ response[0])
				console.log("Endtime:"+ response[1]);
				assert.equal(isBiggerOrEqualThan(response[1],response[0]),true, "StartTime >= Endtime");
			});
		});	
		
		return await ProcessData.at(process).then(async function (result){
		
			assert.equal(isAtMost( await web3.eth.getBalance(TargetOwner),subtraction(fundsTarget,await web3.utils.toWei('2.0', "ether"))),true, "Endstate Funding Target not correct");
			assert.equal(isAtMost( await web3.eth.getBalance(MitigatorOwner),fundsMitigator),true, "Endstate Funding Mitigator not correct");
			assert.equal(isAtMost( await web3.eth.getBalance(process),await web3.utils.toWei('2.0', "ether")),true, "Endstate Funding Contract not correct");
			assert.equal(await result.getState(),7,"State is not abort");
		});
    });	
	
	it("With proof - T selfish, M rational --> payment to M", async function() {
		
		var event = protocol.ProcessDataCreated(function(error, response) {
			if (!error) {
				process = response.args.addr;
			}else{
				console.log(error);
			}
		});

		var listOfAddresses = "Network1,Network2";
		
		//This init is accepted
		await protocol.init(MitigatorOwner,2,2002,listOfAddresses,2, {from: TargetOwner});
		await protocol.approve(process,true, {from: MitigatorOwner});
		
		var fundsTarget = await web3.eth.getBalance(TargetOwner);
		var fundsContract = await web3.eth.getBalance(process);
		
		await protocol.sendFunds(process, {from: TargetOwner,value: await web3.utils.toWei('2.0', "ether")});	
		
		await ProcessData.at(process).then(async function (result){
			assert.equal(isAtMost(await web3.eth.getBalance(TargetOwner),subtraction(fundsTarget,await web3.utils.toWei('2.0', "ether"))),true, "Endstate Target Funding not correct");
		});
		
		await protocol.uploadProof(process,"I've done my job", {from: MitigatorOwner});	
		
		wait(3000); 
		
		await protocol.skipCurrentState(process,{from: TargetOwner});
		
		var fundsMitigator = await web3.eth.getBalance(MitigatorOwner);
	
		await protocol.ratingByMitigator(process,0, {from: MitigatorOwner});
		
		await ProcessData.at(process).then(async function (result){
			await result.getStartAndEndTime().then( async function (response){
				console.log("Starttime:"+ response[0])
				console.log("Endtime:"+ response[1]);
				assert.equal(isBiggerOrEqualThan(response[1],response[0]),true, "StartTime >= Endtime");
			});
		});	
		
		return await ProcessData.at(process).then(async function (result){
		
			assert.equal(isAtMost( await web3.eth.getBalance(TargetOwner),subtraction(fundsTarget,await web3.utils.toWei('2.0', "ether"))),true, "Endstate Funding Target not correct");
			assert.equal(isAtMost( await web3.eth.getBalance(MitigatorOwner),addition(fundsMitigator,await web3.utils.toWei('2.0', "ether"))),true, "Endstate Funding Mitigator not correct");
			assert.equal(isAtMost( await web3.eth.getBalance(process),0),true, "Endstate Funding Contract not correct");
			assert.equal(await result.getState(),6,"State is not complete");
		});
    });	
	
	it("With proof - T selfish, M selfish --> no payment", async function() {
		
		var event = protocol.ProcessDataCreated(function(error, response) {
			if (!error) {
				process = response.args.addr;
			}else{
				console.log(error);
			}
		});

		var listOfAddresses = "Network1,Network2";
		
		//This init is accepted
		await protocol.init(MitigatorOwner,2,2002,listOfAddresses,2, {from: TargetOwner});
		await protocol.approve(process,true, {from: MitigatorOwner});
		
		var fundsTarget = await web3.eth.getBalance(TargetOwner);
		var fundsContract = await web3.eth.getBalance(process);
		
		await protocol.sendFunds(process, {from: TargetOwner,value: await web3.utils.toWei('2.0', "ether")});	
		
		await ProcessData.at(process).then(async function (result){
			assert.equal(isAtMost(await web3.eth.getBalance(TargetOwner),subtraction(fundsTarget,await web3.utils.toWei('2.0', "ether"))),true, "Endstate Target Funding not correct");
		});
		
		await protocol.uploadProof(process,"I've done my job", {from: MitigatorOwner});	
		
		wait(3000); 
		
		await protocol.skipCurrentState(process,{from: TargetOwner});
		
		var fundsMitigator = await web3.eth.getBalance(MitigatorOwner);
	
		wait(3000); 
		await protocol.skipCurrentState(process,{from: TargetOwner});
		
		await ProcessData.at(process).then(async function (result){
			await result.getStartAndEndTime().then( async function (response){
				console.log("Starttime:"+ response[0])
				console.log("Endtime:"+ response[1]);
				assert.equal(isBiggerOrEqualThan(response[1],response[0]),true, "StartTime >= Endtime");
			});
		});	
		
		return await ProcessData.at(process).then(async function (result){
		
			assert.equal(isAtMost( await web3.eth.getBalance(TargetOwner),fundsTarget),true, "Endstate Funding Target not correct");
			assert.equal(isAtMost( await web3.eth.getBalance(MitigatorOwner),fundsMitigator),true, "Endstate Funding Mitigator not correct");
			assert.equal(isAtMost( await web3.eth.getBalance(process),await web3.utils.toWei('2.0', "ether")),true, "Endstate Funding Contract not correct");
			assert.equal(await result.getState(),7,"State is not abort");
		});
    });
	
	it("With proof - T dissatisfied, M rational --> no payment,escalation", async function() {
		
		var event = protocol.ProcessDataCreated(function(error, response) {
			if (!error) {
				process = response.args.addr;
			}else{
				console.log(error);
			}
		});

		var listOfAddresses = "Network1,Network2";
		
		//This init is accepted
		await protocol.init(MitigatorOwner,2,2002,listOfAddresses,2, {from: TargetOwner});
		await protocol.approve(process,true, {from: MitigatorOwner});
		
		var fundsTarget = await web3.eth.getBalance(TargetOwner);
		var fundsContract = await web3.eth.getBalance(process);
		
		await protocol.sendFunds(process, {from: TargetOwner,value: await web3.utils.toWei('2.0', "ether")});	
		
		await ProcessData.at(process).then(async function (result){
			assert.equal(isAtMost(await web3.eth.getBalance(TargetOwner),subtraction(fundsTarget,await web3.utils.toWei('2.0', "ether"))),true, "Endstate Target Funding not correct");
		});
		
		await protocol.uploadProof(process,"I've done my job", {from: MitigatorOwner});	
		
		await protocol.ratingByTarget(process,0, {from: TargetOwner});	
		
		var fundsMitigator = await web3.eth.getBalance(MitigatorOwner);
		
		await protocol.ratingByMitigator(process,0, {from: MitigatorOwner});
		
		await ProcessData.at(process).then(async function (result){
			await result.getStartAndEndTime().then( async function (response){
				console.log("Starttime:"+ response[0])
				console.log("Endtime:"+ response[1]);
				assert.equal(isBiggerOrEqualThan(response[1],response[0]),true, "StartTime >= Endtime");
			});
		});	
		
		return await ProcessData.at(process).then(async function (result){
		
			assert.equal(isAtMost( await web3.eth.getBalance(TargetOwner),subtraction(fundsTarget,await web3.utils.toWei('2.0', "ether"))),true, "Endstate Funding Target not correct");
			assert.equal(isAtMost( await web3.eth.getBalance(MitigatorOwner),fundsMitigator),true, "Endstate Funding Mitigator not correct");
			assert.equal(isAtMost( await web3.eth.getBalance(process),await web3.utils.toWei('2.0', "ether")),true, "Endstate Funding Contract not correct");
			assert.equal(await result.getState(),8,"State is not escalation");
		});
    });
	
	it("With proof - T dissatisfied, M selfish --> payment to T", async function() {
		
		var event = protocol.ProcessDataCreated(function(error, response) {
			if (!error) {
				process = response.args.addr;
			}else{
				console.log(error);
			}
		});

		var listOfAddresses = "Network1,Network2";
		
		//This init is accepted
		await protocol.init(MitigatorOwner,2,2002,listOfAddresses,2, {from: TargetOwner});
		await protocol.approve(process,true, {from: MitigatorOwner});
		
		var fundsTarget = await web3.eth.getBalance(TargetOwner);
		var fundsContract = await web3.eth.getBalance(process);
		
		await protocol.sendFunds(process, {from: TargetOwner,value: await web3.utils.toWei('2.0', "ether")});	
		
		await ProcessData.at(process).then(async function (result){
			assert.equal(isAtMost(await web3.eth.getBalance(TargetOwner),subtraction(fundsTarget,await web3.utils.toWei('2.0', "ether"))),true, "Target Funding not correct");
		});
		
		await protocol.uploadProof(process,"I've done my job", {from: MitigatorOwner});	
		
		await protocol.ratingByTarget(process,0, {from: TargetOwner});	
		
		var fundsMitigator = await web3.eth.getBalance(MitigatorOwner);
		
		wait(3000); 
		
		await protocol.skipCurrentState(process,{from: TargetOwner});
		
		await ProcessData.at(process).then(async function (result){
			await result.getStartAndEndTime().then( async function (response){
				console.log("Starttime:"+ response[0])
				console.log("Endtime:"+ response[1]);
				assert.equal(isBiggerOrEqualThan(response[1],response[0]),true, "StartTime >= Endtime");
			});
		});	
		
		return await ProcessData.at(process).then(async function (result){
		
			assert.equal(isAtMost( await web3.eth.getBalance(TargetOwner),fundsTarget),true, "Endstate Funding Target not correct");
			assert.equal(isAtMost( await web3.eth.getBalance(MitigatorOwner),fundsMitigator),true, "Endstate Funding Mitigator not correct");
			assert.equal(isAtMost( await web3.eth.getBalance(process),0),true, "Endstate Funding Contract not correct");
			assert.equal(await result.getState(),6,"State is not complete");
		});
    });
	
});

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

function isBiggerOrEqualThan(a,b){
	if(a>=b){
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