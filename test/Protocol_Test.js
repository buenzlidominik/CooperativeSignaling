
var Protocol = artifacts.require("./Protocol.sol");
var IActor = artifacts.require("./IActor.sol");
var ProcessData = artifacts.require("./ProcessData.sol");

let catchRevert = require("./exceptions.js").catchRevert;
let senderAccountNotRecognized = require("./exceptions.js").senderAccountNotRecognized;

contract("Protocol", async function(accounts) {
	
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
			//Define the fallback for the event which gives us the address of the created mitigator
			var event = protocol.MitigatorCreated(function(error, response) {
				if (!error) {
					MitigatorAddress = response.args.addr;
				}else{
					console.log(error);
				}
			});
			
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
	
	it("Instantiation", async function() {
		var event = protocol.ProcessDataCreated(function(error, response) {
			if (!error) {
				process = response.args.addr;
			}else{
				console.log(error);
			}
		});
		var listOfAddresses = "Network1,Network2";
		
		//Funds are too low, as our Mitigator needs 1000 per address but we want to block 2 addresses for 1000
		await catchRevert(protocol.init(MitigatorAddress,120,1000,listOfAddresses,2, {from: TargetOwner}));
		
		//List of addresses is not provided and thus reverted
		await catchRevert(protocol.init(MitigatorAddress,120,2002,"",2, {from: TargetOwner}));
		
		//Address is not a registered mitigator
		await catchRevert(protocol.init(accounts[5],120,2002,listOfAddresses,2, {from: TargetOwner}));
		
		//Sender is not allowed to advance
		await senderAccountNotRecognized(protocol.init(MitigatorAddress,120,2002,listOfAddresses,2, {from: MitigatorAddress}));
		
		//This init is accepted
		await protocol.init(MitigatorAddress,120,2002,listOfAddresses,2, {from: TargetOwner});
		return await ProcessData.at(process).then(async function (result){
			assert.equal(await result.getState(), 1, "State is wrong");
			assert.equal(await result.getNextActor(), MitigatorAddress, "NextActor is wrong");
			assert.notEqual(await result.getNextActor(), TargetAddress, "NextActor is wrong");
			assert.equal(await result.getListOfAddresses(), listOfAddresses, "List of addresses is wrong");
		});
    });
	
	it("Approve", async function() {
		
		//Sender is not allowed to advance
		//await senderAccountNotRecognized(await protocol.approve(process,true, {from: TargetOwner}));
		
		//State should be aborted
		await protocol.approve(process,false, {from: MitigatorOwner});
		
		await ProcessData.at(process).then(async function (result){
			assert.equal(await result.getState(), 7, "State is wrong");
			assert.equal(await result.getNextActor(), TargetAddress, "NextActor is wrong");
		});
		
		//Reset state and next actor to init
		await ProcessData.at(process).then(async function (result){
			await result.setState(1);
			await result.setNextActor(MitigatorAddress);
		});

		await protocol.approve(process,true, {from: MitigatorOwner});
		return await ProcessData.at(process).then(async function (result){
			assert.equal(await result.getState(), 2, "State is wrong");
			assert.equal(await result.getNextActor(), TargetAddress, "NextActor is wrong");
		});

    });
});