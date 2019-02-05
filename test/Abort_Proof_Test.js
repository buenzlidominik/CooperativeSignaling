
var Protocol = artifacts.require("./Protocol.sol");
var IActor = artifacts.require("./IActor.sol");
var ProcessData = artifacts.require("./ProcessData.sol");

let catchRevert = require("./exceptions.js").catchRevert;
let senderAccountNotRecognized = require("./exceptions.js").senderAccountNotRecognized;

contract("Abort during proof", async function(accounts) {
	
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
	
	it("Instantiation", async function() {
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
		return await ProcessData.at(process).then(async function (result){
			assert.equal(await result.getState(), 1, "State is wrong");
			assert.equal(await result.getNextActor(), MitigatorAddress, "NextActor is wrong");
			assert.equal(await result.getListOfAddresses(), listOfAddresses, "List of addresses is wrong");
		});
    });
	
	it("Approve", async function() {

		await protocol.approve(process,true, {from: MitigatorOwner});
		return await ProcessData.at(process).then(async function (result){
			assert.equal(await result.getState(), 2, "State is wrong");
			assert.equal(await result.getNextActor(), TargetAddress, "NextActor is wrong");
		});

    });
	
	it("Send Funds", async function() {
		
		await protocol.sendFunds(process, {from: TargetOwner,value: 2002});	
		return await ProcessData.at(process).then(async function (result){
			assert.equal(await result.getState(), 3, "State is wrong");
			assert.equal(await result.getFunds(), 2002, "Contract has wrong funds");
			assert.equal(await result.getNextActor(), MitigatorAddress, "NextActor is wrong");
		});
    });
	
		
	it("Skip State Proof", async function() {
		
		//Cannot be skipped because there is still some time left
		await catchRevert(protocol.skipCurrentState(process,{from: TargetOwner}));
		
		//wait for 11 seconds
		wait(3000); 
		
		await protocol.skipCurrentState(process,{from: TargetOwner});
		await ProcessData.at(process).then(async function (result){
			assert.equal(await result.getState(), 4, "State is wrong");
			assert.equal(await result.getProof(), "", "Proof is wrong");
			assert.equal(await result.getNextActor(), TargetAddress, "NextActor is wrong");
		});
		
		//Cannot be skipped because State is abort
		await catchRevert(protocol.skipCurrentState(process,{from: TargetOwner}));
    });
	
});

function wait(ms){
   var start = new Date().getTime();
   var end = start;
   while(end < start + ms) {
     end = new Date().getTime();
  }
}