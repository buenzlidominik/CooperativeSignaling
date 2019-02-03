pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "./ProcessData.sol";
import "./IActor.sol";
import "./Enums.sol";

contract Protocol {

    address[] private Mitigators;
	address[] private Targets;
    address[] private CurrentProcesses;

    event ProcessDataCreated(address _from, ProcessData addr);
	event MitigatorCreated(address _from, IActor addr);
	event TargetCreated(address _from, IActor addr);
	event FundsReceived(uint256 value);
	
	function() external payable{
		emit FundsReceived(msg.value);
	}
	
	
    function registerMitigator(address payable _MitigatorOwner,uint256 PricePerUnit,string memory NetworkName) public returns(address){
        IActor Mitigator = new IActor(_MitigatorOwner,PricePerUnit,NetworkName);
        Mitigators.push(Mitigator.getAddress());
		emit MitigatorCreated(msg.sender,Mitigator);
        return Mitigator.getAddress();
    }
	
	function registerTarget(address payable _TargetOwner,uint256 PricePerUnit,string memory NetworkName) public returns(address){
        IActor Target = new IActor(_TargetOwner,PricePerUnit,NetworkName);
        Targets.push(Target.getAddress());
		emit TargetCreated(msg.sender,Target);
        return Target.getAddress();
    }

    function init(address _Mitigator,uint _DeadlineInterval,uint256 _OfferedFunds,string memory _ListOfAddresses, uint _NumberOfAddresses) 
    public 
    returns (ProcessData){
        
        require(bytes(_ListOfAddresses).length >0,"no addresses provided");
        require(isMitigator(_Mitigator),"no mitigator");
        require(IActor(_Mitigator).isOfferAcceptable(_OfferedFunds,_NumberOfAddresses),"Funds too low");
        require(senderIsTarget(msg.sender),"Sender is not registered as a Target");
		
        IActor _Target = IActor(getTarget(msg.sender));
        ProcessData newProcessData = new ProcessData(_Target.getAddress(),_Mitigator,_DeadlineInterval,_OfferedFunds,_ListOfAddresses);
        CurrentProcesses.push(newProcessData.getAddress());
		emit ProcessDataCreated(msg.sender,newProcessData);
		
        return newProcessData;
    }

    function approve(address payable process,bool descision) 
    public
    returns (ProcessData){
        
        require(isProcess(process),"Process does not exist");
        require(canSenderAdvance(process,Enums.State.APPROVE),"Sender is not allowed");
        
        ProcessData ProcessToUse = ProcessData(process);
        
        if(descision){
            ProcessToUse.setState(Enums.State.FUNDING);
            ProcessToUse.setNextActor(ProcessToUse.getTarget());
        }else{
            ProcessToUse.setState(Enums.State.ABORT);
			ProcessToUse.setNextActor(ProcessToUse.getTarget());
        }
  
        return ProcessToUse;
    }
    
    function sendFunds(address payable process) 
    public
    payable
    returns (ProcessData){
        
        require(isProcess(process),"Process does not exist");
        require(canSenderAdvance(process,Enums.State.FUNDING),"Sender is not allowed");
        
        ProcessData ProcessToUse = ProcessData(process);
        
        ProcessToUse.getAddress().transfer(msg.value);
        ProcessToUse.setNextActor(ProcessToUse.getMitigator());
        ProcessToUse.setState(Enums.State.PROOF);
        ProcessToUse.setNextDeadline();
        
        return ProcessToUse;
    }
    
    
    function uploadProof(address payable process,string memory _Proof) 
    public
    returns (ProcessData){
        
        require(isProcess(process),"Process does not exist");
        require(canSenderAdvance(process,Enums.State.PROOF),"Sender is not allowed");
        
        ProcessData ProcessToUse = ProcessData(process);
        ProcessToUse.setProof(_Proof);
        ProcessToUse.setNextActor(ProcessToUse.getTarget());
        ProcessToUse.setState(Enums.State.TRATE);
        ProcessToUse.setNextDeadline();
        
        return ProcessToUse;
    }
    
    function ratingByTarget(address payable process,Enums.Rating rating) 
    public
    payable
    returns (ProcessData){
        
        require(isProcess(process),"Process does not exist");
        require(canSenderAdvance(process,Enums.State.TRATE),"Sender is not allowed");
        
        ProcessData ProcessToUse = ProcessData(process);
        
        if(!ProcessToUse.isProofProvided()){
            ProcessToUse.setTargetRating(rating);
			ProcessToUse.setNextActor(ProcessToUse.getTarget());
			ProcessToUse.setState(Enums.State.COMPLETE);
            ProcessToUse.executeEvaluation();
            return ProcessToUse;
        }
        
        ProcessToUse.setTargetRating(rating);
        ProcessToUse.setNextActor(ProcessToUse.getMitigator());
        ProcessToUse.setState(Enums.State.MRATE);
        ProcessToUse.setNextDeadline();
        
        return ProcessToUse;
         
    }
    
    function ratingByMitigator(address payable process,Enums.Rating rating) 
    public
    payable
    returns (ProcessData){
        
        require(isProcess(process),"Process does not exist");
		
        require(canSenderAdvance(process,Enums.State.MRATE),"Sender is not allowed to advance due to: ");
        
        ProcessData ProcessToUse = ProcessData(process);
        ProcessToUse.setMitigatorRating(rating);
		ProcessToUse.setNextActor(ProcessToUse.getTarget());
        ProcessToUse.executeEvaluation();

        return ProcessToUse;
    }
	
	function canCurrentStateBeSkipped(address payable process) private returns(bool){
		return false;
	}
   
    /*Checks where the sender of the message is the next actor and the state 
    of the action to be performed is the one immediately following in the process
    and if deadline is exceeded*/
    function canSenderAdvance(address payable process,Enums.State newState) 
    private 
    view
    returns(bool){
        
		require(isProcess(process),"Process not found");
        ProcessData CurrentProcess = getProcess(process);

        require(CurrentProcess.getNextActor().getOwner() == msg.sender,"NextActor != Sender");
        require(uint(newState)==uint(CurrentProcess.getState()),"Next state would be lower");
        if(CurrentProcess.getState()<uint(Enums.State.FUNDING)){
            require(now>CurrentProcess.getDeadline(),"state >=start && now > deadline");
        }
        
        return true;
    }
	
	function getProcess(address payable process) 
    public view 
    returns(ProcessData){
        for (uint i = 0 ; i < CurrentProcesses.length; i++) {
            if(CurrentProcesses[i]==process){
                return ProcessData(process);
            }
        }
		return ProcessData(0);
    }
	
    function getProcesses() 
    public view 
    returns(address[] memory){
        return CurrentProcesses;
    }
    

    function getStateOfProcess(address payable process) 
    public view 
    returns(address payable,address payable,address payable,uint,string memory,uint,uint,uint){
        ProcessData ProcessToUse = ProcessData(process);
        return (ProcessToUse.getTarget().getOwner(),ProcessToUse.getMitigator().getOwner(),ProcessToUse.getNextActor().getOwner()
        ,ProcessToUse.getFunds(),ProcessToUse.getProof(),uint(ProcessToUse.getState())
        ,uint(ProcessToUse.getTargetRating()),uint(ProcessToUse.getMitigatorRating()));
    }
    
    function isProcess(address payable process) 
    private view 
    returns(bool){
        for (uint i = 0 ; i < CurrentProcesses.length; i++) {
            if(CurrentProcesses[i]==process){
                return true;
            }
        }
        return false;
    }
    
    function isMitigator(address mitigator) 
    private view 
    returns(bool){
        for (uint i = 0 ; i < Mitigators.length; i++) {
            if(Mitigators[i]==mitigator){
                return true;
            }
        }
        return false;
    }
	
	function senderIsTarget(address payable owner) 
    private view 
    returns(bool){
        for (uint i = 0 ; i < Targets.length; i++) {
            if(IActor(Targets[i]).getOwner()==owner){
                return true;
            }
        }
        return false;
    }
	
	function getTarget(address payable owner) 
    private view 
    returns(address){
        for (uint i = 0 ; i < Targets.length; i++) {
            if(IActor(Targets[i]).getOwner()==owner){
                return Targets[i];
            }
        }
		return address(0);
    }
}