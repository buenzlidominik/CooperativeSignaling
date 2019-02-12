
var Protocol = artifacts.require("./Protocol.sol");
var IActor = artifacts.require("./IActor.sol");
var ProcessData = artifacts.require("./ProcessData.sol");

let catchRevert = require("./exceptions.js").catchRevert;
let senderAccountNotRecognized = require("./exceptions.js").senderAccountNotRecognized;

contract("Full Run Test", async function(accounts) {
	
	var protocol;
    var process;
	
    var TargetOwner = accounts[0];
	var MitigatorOwner = accounts[1];
	var listOfAddresses = "Network1,Network2";
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
	
	it("Instantiation", async function() {
		var event = protocol.ProcessDataCreated(function(error, response) {
			if (!error) {
				process = response.args.addr;
			}else{
				console.log(error);
			}
		});

		
		//Funds are too low, as our Mitigator needs 1000 per address but we want to block 2 addresses for 1000
		await catchRevert(protocol.init(MitigatorOwner,120,1000,listOfAddresses,2, {from: TargetOwner}));
		
		//List of addresses is not provided and thus reverted
		await catchRevert(protocol.init(MitigatorOwner,120,2002,"",2, {from: TargetOwner}));
		
		//Address is not a registered mitigator
		await catchRevert(protocol.init(accounts[5],120,2002,listOfAddresses,2, {from: TargetOwner}));
		
		//Sender is not allowed to advance
		await catchRevert(protocol.init(MitigatorOwner,120,2002,listOfAddresses,2, {from: MitigatorOwner}));
		
		//Sender is not a registered target
		await catchRevert(protocol.init(MitigatorOwner,120,2002,listOfAddresses,2, {from: accounts[2]}));
		
		//This init is accepted
		await protocol.init(MitigatorOwner,120,2002,listOfAddresses,2, {from: TargetOwner});
		return await ProcessData.at(process).then(async function (result){
			assert.equal(await result.getState(), 1, "State is wrong");
			assert.equal(await result.getNextActor(), MitigatorAddress, "NextActor is wrong");
			assert.equal(await result.getListOfAddresses(), listOfAddresses, "List of addresses is wrong");
		});
    });
	
	
	it("Approve", async function() {
		
		var event = protocol.ProcessDataCreated(function(error, response) {
			if (!error) {
				process = response.args.addr;
			}else{
				console.log(error);
			}
		});

		//Sender is not allowed to advance
		await catchRevert(protocol.approve(process,true, {from: TargetOwner}));

		//State should be aborted
		await protocol.approve(process,false, {from: MitigatorOwner});	
		await ProcessData.at(process).then(async function (result){
			assert.equal(await result.getState(), 7, "State is wrong");
			assert.equal(await result.getNextActor(), TargetAddress, "NextActor is wrong");
		});
		
		//Reinstantiate proces
		await protocol.init(MitigatorOwner,120,2002,listOfAddresses,2, {from: TargetOwner});
		await ProcessData.at(process).then(async function (result){
			assert.equal(await result.getState(), 1, "State is wrong");
			assert.equal(await result.getNextActor(), MitigatorAddress, "NextActor is wrong");
			assert.equal(await result.getListOfAddresses(), listOfAddresses, "List of addresses is wrong");
		});

		await protocol.approve(process,true, {from: MitigatorOwner});
		return await ProcessData.at(process).then(async function (result){
			assert.equal(await result.getState(), 2, "State is wrong");
			assert.equal(await result.getNextActor(), TargetAddress, "NextActor is wrong");
		});

    });
	
	it("Try to delete actor although in process", async function() {
	
		//Will be reverted because mid process and wrong sender
		await catchRevert(protocol.deleteActor(MitigatorOwner, {from: TargetOwner}));

		//Will be reverted because mid process
		await catchRevert(protocol.deleteActor(MitigatorOwner, {from: MitigatorOwner}));
		
		//Will be reverted because mid process
		await catchRevert(protocol.deleteActor(TargetOwner, {from: TargetOwner}));
		
    });
	
	it("Send Funds", async function() {
		
		var fundsTarget = await web3.eth.getBalance(TargetOwner);
		
		//Funds are too low, will be reverted
		await catchRevert(protocol.sendFunds(process, {from: TargetOwner,value: 2000}));	
		
		//Wrong sender, will be reverted
		await catchRevert(protocol.sendFunds(process, {from: MitigatorOwner,value: 2002}));	
		
		//Will work
		await protocol.sendFunds(process, {from: TargetOwner,value: await web3.utils.toWei('2.0', "ether")});	
		return await ProcessData.at(process).then(async function (result){
			assert.equal(await result.getState(), 3, "State is wrong");
			assert.equal(await result.getFunds(), await web3.utils.toWei('2.0', "ether"), "Contract has wrong funds");
			assert.equal(await result.getNextActor(), MitigatorAddress, "NextActor is wrong");
			assert.equal(isAtMost(await web3.eth.getBalance(TargetOwner),subtraction(fundsTarget,await web3.utils.toWei('2.0', "ether"))),true, "Funds not taken away from Target");
		});
		
		
    });
	
	it("Upload Proof", async function() {
		
		//Try to use wrong state operation
		await catchRevert(protocol.ratingByMitigator(process,2, {from: MitigatorOwner}));	
		
		//Wrong sender,will be reverted
		await catchRevert(protocol.uploadProof(process,"I've done my job", {from: TargetOwner}));	
		
		//Empty string, will be reverted
		await catchRevert(protocol.uploadProof(process,"", {from: MitigatorOwner}));	
		
		//Try to use wrong state operation
		await catchRevert(protocol.approve(process,true, {from: MitigatorOwner}));	
		
		//Will work
		await protocol.uploadProof(process,"I've done my job", {from: MitigatorOwner});	
		return await ProcessData.at(process).then(async function (result){
			assert.equal(await result.getState(), 4, "State is wrong");
			assert.equal(await result.getProof(), "I've done my job", "Proof is wrong");
			assert.equal(await result.getNextActor(), TargetAddress, "NextActor is wrong");
		});
    });
	
	it("Rate By Target", async function() {
	
		//Try to use wrong state operation (current state is lower)
		await catchRevert(protocol.ratingByMitigator(process,2, {from: TargetOwner}));	
		
		//Wrong sender,will be reverted
		await catchRevert(protocol.ratingByTarget(process,2, {from: MitigatorOwner}));	

		//Will work
		await protocol.ratingByTarget(process,2, {from: TargetOwner});	
		await ProcessData.at(process).then(async function (result){
			assert.equal(await result.getState(), 5, "State is wrong");
			assert.equal(await result.getTargetRating(), 2, "Proof is wrong");
			assert.equal(await result.getNextActor(), MitigatorAddress, "NextActor is wrong");
		});
		
		//Called state function twice, will be reverted
		return await catchRevert(protocol.ratingByTarget(process,2, {from: TargetOwner}));	
    });
	
	it("Rate By Mitigator", async function() {
	
		//Try to use wrong state operation (current state is lower)
		await catchRevert(protocol.ratingByTarget(process,2, {from: MitigatorOwner}));	
		
		//Wrong sender,will be reverted
		await catchRevert(protocol.ratingByMitigator(process,2, {from: TargetOwner}));	

		//Will work
		await protocol.ratingByMitigator(process,2, {from: MitigatorOwner});	
		await ProcessData.at(process).then(async function (result){
			assert.equal(await result.getState(), 6, "State is wrong");
			assert.equal(await result.getMitigatorRating(), 2, "Proof is wrong");
			assert.equal(await result.getNextActor(), TargetAddress, "NextActor is wrong");
		});
		
		//Called state function twice, will be reverted
		await catchRevert(protocol.ratingByMitigator(process,2, {from: MitigatorOwner}));
    });
	
	it("Delete Mitigator", async function() {
	
		//Will work
		await protocol.deleteActor(MitigatorOwner, {from: MitigatorOwner});	
		await protocol.getActors().then(async function (result){
			assert.equal(result.includes(MitigatorOwner), false, "Actor not deleted");
		});	
    });
	
	it("Delete Target", async function() {
	
		//Will work
		await protocol.deleteActor(TargetOwner, {from: TargetOwner});	
		await protocol.getActors().then(async function (result){
			assert.equal(result.includes(TargetOwner), false, "Actor not deleted");
		});	
    });

});

function isBiggerOrEqualThan(a,b){
	if(a>=b){
		return true;
	}	
	return false;
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