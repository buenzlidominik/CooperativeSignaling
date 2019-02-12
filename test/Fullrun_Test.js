
var Protocol = artifacts.require("./Protocol.sol");
var IActor = artifacts.require("./IActor.sol");
var Process = artifacts.require("./Process.sol");
var IData = artifacts.require("./IData.sol");
var IState = artifacts.require("./IState.sol");
let catchRevert = require("./Exceptions.js").catchRevert;

contract("Full Run Test", async function(accounts) {
	
	var protocol;
    var process;
	
    var TargetOwner = accounts[0];
	var MitigatorOwner = accounts[1];
	var listOfAddresses = "Network1,Network2";
	var Address;
	var MitigatorAddress;
	var TargetAddress;
	var fundsTarget;
	
    it("Actor Creation", async function() {
        return await Protocol.deployed().then(async function(instance) {          

			protocol = instance;

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
		
		await protocol.init(MitigatorOwner,120,2002,listOfAddresses,2, {from: TargetOwner});
		await Process.at(process).then(async function (result){
			
			
		});
		return await Process.at(process).then(async function (result){
			await IState.at(await result.getState()).then(async function (state){
				assert.equal(await state.getStateType(),1,"State is not APPROVE");
				assert.equal(await state.getOwnerOfState(), MitigatorOwner, "NextActor is wrong");
			});
			await IData.at(await result.getData()).then(async function (data){
				assert.equal(await data.getListOfAddresses(), listOfAddresses, "List of addresses is wrong");
			});
		});
    });

	it("Approve", async function() {
		
		//this will revert because the state is too high
		await catchRevert(protocol.sendFunds(process, {from: TargetOwner,value: await web3.utils.toWei('2.0', "ether")}));
		
		await protocol.approve(process,true, {from: MitigatorOwner});
		
		return await Process.at(process).then(async function (result){
			await IState.at(await result.getState()).then(async function (state){
				assert.equal(await state.getStateType(),2,"State is not FUNDING");
				assert.equal(await state.getOwnerOfState(), TargetOwner, "NextActor is wrong");
			});
		});
    });
	
	it("Send Funds", async function() {
	
		fundsTarget = await web3.eth.getBalance(TargetOwner);

		await protocol.sendFunds(process, {from: TargetOwner,value: await web3.utils.toWei('2.0', "ether")});	
		
		return await Process.at(process).then(async function (result){
			await IState.at(await result.getState()).then(async function (state){
				assert.equal(await state.getStateType(),3,"State is not PROOF");
				assert.equal(await state.getOwnerOfState(), MitigatorOwner, "NextActor is wrong");
			});
			await result.getData().then(async function (data){
				assert.equal(await web3.eth.getBalance(data), await web3.utils.toWei('2.0', "ether"), "Wrong funds");
			});
		});
		
		
    });

	it("Upload Proof", async function() {
		
		//this will revert because the state is too low
		await catchRevert(protocol.approve(process,true, {from: MitigatorOwner}));
		
		await protocol.uploadProof(process,"I've done my job", {from: MitigatorOwner});	
		
		return await Process.at(process).then(async function (result){
			await IState.at(await result.getState()).then(async function (state){
				assert.equal(await state.getStateType(),4,"State is not RATE_T");
				assert.equal(await state.getOwnerOfState(), TargetOwner, "NextActor is wrong");
			});
			await IData.at(await result.getData()).then(async function (data){
				assert.equal(await data.getProof(), "I've done my job", "Proof not set");
			});
		});
    });
	
	it("Rate By Target", async function() {

		await protocol.rateByTarget(process,2, {from: TargetOwner});	
		return await Process.at(process).then(async function (result){
			await IState.at(await result.getState()).then(async function (state){
				assert.equal(await state.getStateType(),5,"State is not RATE_M");
				assert.equal(await state.getOwnerOfState(), MitigatorOwner, "NextActor is wrong");
			});
			await IData.at(await result.getData()).then(async function (data){
				assert.equal(await data.getTargetRating(),2, "Proof not set");
			});
		});
    });
	
	it("Rate By Mitigator", async function() {
		
		var fundsMitigator = await web3.eth.getBalance(MitigatorOwner);
		
		await protocol.rateByMitigator(process,2, {from: MitigatorOwner});
		return await Process.at(process).then(async function (result){
			await IState.at(await result.getState()).then(async function (state){
				assert.equal(await state.getStateType(),7,"State is not COMPLETE");
				//this will revert because COMPLETE has no owner
				await catchRevert(state.getOwnerOfState());
			});
			
			await result.getData().then(async function (data){
				assert.equal(isAtMost( await web3.eth.getBalance(TargetOwner),subtraction(fundsTarget,await web3.utils.toWei('2.0', "ether"))),true, "Endstate Funding Target not correct");
				assert.equal(isAtMost( await web3.eth.getBalance(MitigatorOwner),addition(fundsMitigator,await web3.utils.toWei('2.0', "ether"))),true, "Endstate Funding Mitigator not correct");
				assert.equal(await web3.eth.getBalance(data),0, "Endstate Funding Contract not correct");
			});

			await IData.at(await result.getData()).then(async function (data){
				assert.equal(await data.getMitigatorRating(),2, "Proof not set");
			});
		});	
    });
	it("Time", async function() {
	
		return await Process.at(process).then(async function (result){
			await IData.at(await result.getData()).then(async function (data){
					console.log("StartTime: "+await data.getStartTime());
					console.log("EndTime: "+await data.getEndTime());
					console.log("Duration: "+subtraction(await data.getEndTime(),await data.getStartTime()));
			});
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