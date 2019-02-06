
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

			await protocol.registerActor(TargetOwner,1000,"Target1", {from: TargetOwner});
			TargetAddress = Address;

		});
    });
	
	it("Time To Finish", async function() {
		var event = protocol.ProcessDataCreated(function(error, response) {
			if (!error) {
				process = response.args.addr;
			}else{
				console.log(error);
			}
		});
		
		await protocol.init(MitigatorOwner,120,2002,listOfAddresses,2, {from: TargetOwner});
		await protocol.approve(process,true, {from: MitigatorOwner});
		await protocol.sendFunds(process, {from: TargetOwner,value: await web3.utils.toWei('2.0', "ether")});	
		await protocol.uploadProof(process,"I've done my job", {from: MitigatorOwner});	
		await protocol.ratingByTarget(process,2, {from: TargetOwner});	
		await protocol.ratingByMitigator(process,2, {from: MitigatorOwner});	
		
		await ProcessData.at(process).then(async function (result){
			await result.getStartAndEndTime().then( async function (response){
				console.log("Starttime:"+ response[0])
				console.log("Endtime:"+ response[1]);
				assert.equal(isBiggerOrEqualThan(response[1],response[0]),true, "StartTime >= Endtime");
			});
		});

    });

});

function isBiggerOrEqualThan(a,b){
	if(a>=b){
		return true;
	}	
	return false;
}
