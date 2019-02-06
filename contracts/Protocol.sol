pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "./ProcessData.sol";
import "./IActor.sol";
import "./Enums.sol";

contract Protocol {

    address[] private Actors;
    address payable[] private CurrentProcesses;

    event ProcessDataCreated(address _from, ProcessData addr);
	event ActorCreated(address _from, address addr);
	event FundsReceived(uint256 value);
	
	function() external payable{
		emit FundsReceived(msg.value);
	}

    function registerActor(address payable _Owner,uint256 PricePerUnit,string memory NetworkName) public returns(address){
        require(!ownerIsActor(_Owner),"The provided address is already registered as an actor");
		require(_Owner==msg.sender,"The sender is not the owner of the address");
		IActor _Actor = new IActor(_Owner,PricePerUnit,NetworkName);
        Actors.push(address(_Actor));
		emit ActorCreated(msg.sender,address(_Actor));
        return address(_Actor);
    }
	
	function deleteActor(address payable _Owner) public{
		require(_Owner == msg.sender,"The sender is not the owner of the actor");
		require(notInActiveProcesses(_Owner),"The sender is involved in an active process");
		uint id = getActorIndexFromOwner(_Owner);
		require(CurrentProcesses.length > 0,"Empty actor list");
		Actors[id] = Actors[Actors.length-1];
		Actors.length = Actors.length-1;
    }
	
	function notInActiveProcesses(address payable _Owner) private view returns(bool){
		require(ownerIsActor(_Owner),"Owner is not an actor");
		IActor actor = IActor(getActor(_Owner));
		for (uint i = 0 ; i < CurrentProcesses.length; i++) {
			ProcessData CurrentProcess = getProcess(CurrentProcesses[i]);
			if(CurrentProcess.getState()<uint(Enums.State.COMPLETE)){
				if(CurrentProcess.getTarget()==actor){
					return false;
				}
				if(CurrentProcess.getMitigator()==actor){
					return false;
				}
			} 
        }
		return true;
	}
	
    function init(address payable _MitigatorOwner,uint _DeadlineInterval,uint256 _OfferedFunds,string memory _ListOfAddresses, uint _NumberOfAddresses) 
    public 
    returns (ProcessData){
        
        require(bytes(_ListOfAddresses).length >0,"no addresses provided");
        require(ownerIsActor(_MitigatorOwner),"No registered actor");
		require(ownerIsActor(msg.sender),"Sender is not registered as an actor");
		require(msg.sender!=_MitigatorOwner,"Sender and target cannot be the same");
		IActor _Mitigator = IActor(getActor(_MitigatorOwner));
        require(IActor(_Mitigator).isOfferAcceptable(_OfferedFunds,_NumberOfAddresses),"Funds too low");
		
        ProcessData newProcessData = new ProcessData(address(getActor(msg.sender)),address(_Mitigator),_DeadlineInterval,_OfferedFunds,_ListOfAddresses);
        CurrentProcesses.push(address(newProcessData));
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
            ProcessToUse.advanceState();
        }else{
            ProcessToUse.endProcess(Enums.State.ABORT);
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
        
        address(ProcessToUse).transfer(msg.value);
		
        ProcessToUse.advanceState();
        
        return ProcessToUse;
    }
    
    
    function uploadProof(address payable process,string memory _Proof) 
    public
    returns (ProcessData){
        
        require(isProcess(process),"Process does not exist");
        require(canSenderAdvance(process,Enums.State.PROOF),"Sender is not allowed");
        
        ProcessData ProcessToUse = ProcessData(process);
        ProcessToUse.setProof(_Proof);
		
        ProcessToUse.advanceState();
        
        return ProcessToUse;
    }
    
    function ratingByTarget(address payable process,Enums.Rating rating) 
    public
    payable
    returns (ProcessData){
        
        require(isProcess(process),"Process does not exist");
        require(canSenderAdvance(process,Enums.State.TRATE),"Sender is not allowed");
        
        ProcessData ProcessToUse = ProcessData(process);
        ProcessToUse.setTargetRating(rating);
        
		if(!ProcessToUse.isProofProvided()){
            ProcessToUse.executeEvaluation();
            return ProcessToUse;
        }
		
        ProcessToUse.advanceState();
		
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
        ProcessToUse.executeEvaluation();

        return ProcessToUse;
    }
	
	function skipCurrentState(address payable process) public returns(ProcessData){
		
		require(isProcess(process),"Process not found");
        ProcessData CurrentProcess = getProcess(process);
		require(CurrentProcess.getState()<uint(Enums.State.COMPLETE),"Process is already aborted, completed or escalated");
		
		if(CurrentProcess.getState()<uint(Enums.State.PROOF)){
			require(msg.sender== CurrentProcess.getTarget().getOwner(),"In this state, the process can only be aborted by the initiator");
			CurrentProcess.endProcess(Enums.State.ABORT);
			return CurrentProcess;
		}
		
		require(now>CurrentProcess.getDeadline(),"Deadline not yet exceeded, please wait");

		if(CurrentProcess.getState() == uint(Enums.State.TRATE)){
			CurrentProcess.setTargetRating(Enums.Rating.NA);
		}else if(CurrentProcess.getState() == uint(Enums.State.MRATE)){
			CurrentProcess.setMitigatorRating(Enums.Rating.NA);
		}
		
		CurrentProcess.advanceState();
		
		return CurrentProcess;
	}
   
    /*Checks where the sender of the message is the next actor and the state 
    of the action to be performed is the one immediately following in the process
    and if deadline is exceeded*/
    function canSenderAdvance(address payable process,Enums.State stateOfOperation) 
    private 
    view
    returns(bool){
        
		require(isProcess(process),"Process not found");
        ProcessData CurrentProcess = getProcess(process);
		
		require(CurrentProcess.getNextActor().getOwner() == msg.sender,"NextActor != Sender");
		require(uint(stateOfOperation)==CurrentProcess.getState(),"State of operation does not match");
		if(CurrentProcess.getState()>uint(Enums.State.FUNDING)){
			require(now<CurrentProcess.getDeadline(),"State > Funding && now > deadline, please skip the state");
		}
        return true;
    }
	
	function getProcess(address payable process) 
    private view 
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
    returns(address payable[] memory){
        return CurrentProcesses;
    }
	
	function getActors() 
    public view 
    returns(address[] memory){
        return Actors;
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
    
    function addressIsActor(address actor) 
    private view 
    returns(bool){
        for (uint i = 0 ; i < Actors.length; i++) {
            if(Actors[i]==actor){
                return true;
            }
        }
        return false;
    }
	
	function getActorIndexFromOwner(address payable owner) 
    private view 
    returns(uint){
        for (uint i = 0 ; i < Actors.length; i++) {
            if(IActor(Actors[i]).getOwner()==owner){
                return i;
            }
        }
        return 0;
    }
	
	function ownerIsActor(address payable owner) 
    private view 
    returns(bool){
        for (uint i = 0 ; i < Actors.length; i++) {
            if(IActor(Actors[i]).getOwner()==owner){
                return true;
            }
        }
        return false;
    }
	
	function getActor(address payable owner) 
    private view 
    returns(address){
        for (uint i = 0 ; i < Actors.length; i++) {
            if(IActor(Actors[i]).getOwner()==owner){
                return Actors[i];
            }
        }
		return address(0);
    }
}