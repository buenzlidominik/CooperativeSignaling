pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "./Process.sol";
import "./IActor.sol";

contract Protocol {

    address payable[] private Actors;
    address payable[] private CurrentProcesses;

    event ProcessCreated(address _from, address addr);
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
		return true;
	}
	
    function init(address payable _MitigatorOwner,uint _DeadlineInterval,uint256 _OfferedFunds,string memory _ListOfAddresses, uint _NumberOfAddresses) 
    public 
    returns (address){
        
        require(bytes(_ListOfAddresses).length >0,"no addresses provided");
        require(ownerIsActor(_MitigatorOwner),"No registered actor");
		require(ownerIsActor(msg.sender),"Sender is not registered as an actor");
		require(msg.sender!=_MitigatorOwner,"Sender and target cannot be the same");
		IActor _Mitigator = IActor(getActor(_MitigatorOwner));
        require(_Mitigator.isOfferAcceptable(_OfferedFunds,_NumberOfAddresses),"Funds too low");
        
        Process newProcess = new Process();
        newProcess.init(getActor(msg.sender),getActor(_MitigatorOwner),_DeadlineInterval,_ListOfAddresses,_NumberOfAddresses);
        
        CurrentProcesses.push(address(newProcess));
		
		emit ProcessCreated(msg.sender,address(newProcess));
		
        return address(newProcess);
        
    }

    function approve(address payable process,bool descision) 
    public
    payable
    returns (address){
        
        require(isProcess(process),"no process");
        Process(process).approve(descision);
        
        return process;
    }
    
    function sendFunds(address payable process) 
    public
    payable
    returns (address){
        
        require(isProcess(process),"no process");
        process.transfer(msg.value);
		Process(process).sendFunds();
        return process;
    }
    
    function uploadProof(address payable process,string memory proof) 
    public
    returns (address){
        
        require(isProcess(process),"no process");
        Process(process).uploadProof(proof);
        
        return process;
    }
    
    function rateByMitigator(address payable process,uint rating) 
    public
    returns (address){
        
        require(isProcess(process),"no process");
        Process(process).rateByMitigator(rating);
        
        return process;
    }
    
    function rateByTarget(address payable process,uint rating) 
    public
    returns (address){
        
        require(isProcess(process),"no process");
        Process(process).rateByTarget(rating);
        
        return process;
    }
   
   
	function skipCurrentState(address payable process) public{
		
	}

    function getProcesses() 
    public view 
    returns(address payable[] memory){
        return CurrentProcesses;
    }
	
	function getActors() 
    public view 
    returns(address payable[] memory){
        return Actors;
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
    returns(address payable){
        for (uint i = 0 ; i < Actors.length; i++) {
            if(IActor(Actors[i]).getOwner()==owner){
                return Actors[i];
            }
        }
		return address(0);
    }
}