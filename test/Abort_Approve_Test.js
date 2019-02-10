
var Protocol = artifacts.require("./Protocol.sol");
var IActor = artifacts.require("./IActor.sol");
var Process = artifacts.require("./Process.sol");
var IData = artifacts.require("./IData.sol");
var IState = artifacts.require("./IState.sol");
let catchRevert = require("./Exceptions.js").catchRevert;

contract("Abort during approve", async function(accounts) {
	
	var protocol;
    var process;
	
    var TargetOwner = accounts[0];
	var MitigatorOwner = accounts[1];
	var Address;
	var MitigatorAddress;
	var TargetAddress;
	
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
		var event = protocol.ProcessDataCreated(function(error, response) {
			if (!error) {
				process = response.args.addr;
			}else{
				console.log(error);
			}
		});
		var listOfAddresses = "Network1,Network2";

		await protocol.init(MitigatorOwner,1000,2002,listOfAddresses,2, {from: TargetOwner});

		return await Process.at(process).then(async function (result){
			await IState.at(await result.getState()).then(async function (state){
				assert.equal(await state.getStateType(),1,"State is not APPROVE");
				assert.equal(await state.getOwnerOfState(), MitigatorOwner, "NextActor is wrong");
			});
			await IData.at(await result.getData()).then(async function (data){
				assert.equal(await data.getOfferedFunds(), 2002, "List of addresses is wrong");
			});
		});
    });
	
	
	it("Abort Approve State", async function() {
		
		return await Process.at(process).then(async function (result){
			await IState.at(await result.getState()).then(async function (state){
				await state.abort({from: MitigatorOwner});
				assert.equal(await state.getStateType(),8,"State is not ABORT");
				await catchRevert(state.getOwnerOfState());
			});
		});

    });
});

function wait(ms){
   var start = new Date().getTime();
   var end = start;
   while(end < start + ms) {
     end = new Date().getTime();
  }
}