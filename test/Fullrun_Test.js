
var Protocol = artifacts.require("./Protocol.sol");
var IActor = artifacts.require("./IActor.sol");
var Process = artifacts.require("./Process.sol");
var IData = artifacts.require("./IData.sol");
var IState = artifacts.require("./IState.sol");

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
		var event = protocol.ProcessCreated(function(error, response) {
			if (!error) {
				process = response.args.addr;
			}else{
				console.log(error);
			}
		});
		
		
		//This init is accepted
		await protocol.init(MitigatorOwner,120,2002,listOfAddresses,2, {from: TargetOwner});
		//return await Process.at(process).then(async function (result){
		//	assert.equal(await result.getNextActor(), MitigatorAddress, "NextActor is wrong");
		//	assert.equal(await result.getListOfAddresses(), listOfAddresses, "List of addresses is wrong");
		//});
    });
	
	
	it("Approve", async function() {
		
		await protocol.approve(process,true, {from: MitigatorOwner});
		await Process.at(process).then(async function (result){
			await IState.at(await result.getState()).then(async function (response){
				console.log(await response.getName());
			});
		});

    });
	
	it("Send Funds", async function() {
		
		var fundsTarget = await web3.eth.getBalance(TargetOwner);

		//Will work
		await protocol.sendFunds(process, {from: TargetOwner,value: await web3.utils.toWei('2.0', "ether")});	
		
		//return await Process.at(process).then(async function (result){
		//	assert.equal(await result.getState(), 3, "State is wrong");
		//	assert.equal(await result.getFunds(), await web3.utils.toWei('2.0', "ether"), "Contract has wrong funds");
		//	assert.equal(await result.getNextActor(), MitigatorAddress, "NextActor is wrong");
		//	assert.equal(isAtMost(await web3.eth.getBalance(TargetOwner),subtraction(fundsTarget,await web3.utils.toWei('2.0', "ether"))),true, "Funds not taken away from Target");
		//});
		
		
    });
	
	it("Upload Proof", async function() {
		
		//Will work
		await protocol.uploadProof(process,"I've done my job", {from: MitigatorOwner});	
		//return await Process.at(process).then(async function (result){
		//	assert.equal(await result.getState(), 4, "State is wrong");
		//	assert.equal(await result.getProof(), "I've done my job", "Proof is wrong");
		//	assert.equal(await result.getNextActor(), TargetAddress, "NextActor is wrong");
		//});
    });
	
	it("Rate By Target", async function() {
	

		//Will work
		await protocol.rateByTarget(process,2, {from: TargetOwner});	
		//await Process.at(process).then(async function (result){
		//	assert.equal(await result.getState(), 5, "State is wrong");
		//	assert.equal(await result.getTargetRating(), 2, "Proof is wrong");
		//	assert.equal(await result.getNextActor(), MitigatorAddress, "NextActor is wrong");
		//});
		
		//Called state function twice, will be reverted
    });
	
	it("Rate By Mitigator", async function() {
	
		//await Process.at(process).then(async function (result){
			//await result.getStartAndEndTime().then( async function (response){
			//	console.log("Starttime:"+ response[0])
			//	console.log("Endtime:"+ response[1]);
			//	assert.equal(isBiggerOrEqualThan(response[1],response[0]),true, "StartTime >= Endtime");
			//});
		//});		
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