pragma solidity ^0.5.0;
import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/Protocol.sol";
import "../contracts/IActor.sol";


contract Protocol_test {

    //IActor _Target = new IActor(msg.sender,1,"TargetNetwork");
	
    address Mitigator1;
    Protocol protocol;
    ProcessData process;
    string networks = "Addresses";
    
    function beforeAll() public {
         protocol = Protocol(DeployedAddresses.Protocol());
        Mitigator1=protocol.registerMitigator(address(0x14723a09acff6d2a60dcdf7aa4aff308fddc160c00),1000,"Mitigator1");
    }

    /// sender: account-0
    function init() public {
        process =protocol.init(Mitigator1,120,1001,networks,1);
        //Assert.equal(process.getState().getStateName(),"Start", "Process State is wrong after init");
        //Assert.equal(IData(process.getState().getData()).getTarget().getAddress(),_Target.getAddress(), "Target is wrong");
        //Assert.equal(IData(process.getState().getData()).getMitigator().getAddress(),_Mitigator.getAddress(), "Mitigator is wrong");
        //Assert.equal(process.getState(),msg.sender, "Executor is wrong, needs to be Target");
        
        //process = process.approve(true);
        
        //Assert.equal(process.getState().getStateName(),"Approve", "Process State is wrong after init");
        //Assert.equal(process.getState().getActorOfState().getAddress(),_Mitigator.getAddress(), "Executor is wrong, needs to be Mitigator");
        //process =protocol.approve(process.getAddress(),true);
        //Assert.equal(process.getState(),3, "Process State is wrong");
        //return;
    }
}
