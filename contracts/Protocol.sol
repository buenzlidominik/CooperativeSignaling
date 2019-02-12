pragma solidity ^0.5.0;

import "./Enums.sol";

contract Protocol {

    address payable private Target;
	address payable private Mitigator;
	Enums.State CurrentState;
	string private ListOfAddresses;
	string private Proof;
	uint256 private OfferedFunds;
	Enums.Rating private TargetRating;
	Enums.Rating private MitigatorRating;
	uint256 private StartTime = now;
	uint256 private EndTime;
	uint256 private DeadlineInterval;
	uint256 private CurrentDeadline;
    event ProcessCreated(address _from, address addr);
	event FundsReceived(uint256 value);
	
	constructor() public payable{}
	
	function() external payable{
		emit FundsReceived(msg.value);
	}

    function init(address payable _Mitigator,uint _DeadlineInterval,uint256 _OfferedFunds,string memory _ListOfAddresses) 
    public {
        
        require(msg.sender==Target,"sender is not required actor");
		Mitigator = _Mitigator;
		Target = msg.sender;
		DeadlineInterval=_DeadlineInterval;
		OfferedFunds=_OfferedFunds;
		ListOfAddresses=_ListOfAddresses;
		CurrentState = Enums.State.APPROVE;
		emit ProcessCreated(msg.sender,address(this));
    }

    function approve(bool descision) 
    public{
        
		require(msg.sender==Mitigator,"sender is not required actor");
        require(CurrentState==Enums.State.REQUEST,"State is not appropriate");

        if(descision){
            CurrentState = Enums.State.FUNDING;
        }else{
            CurrentState = Enums.State.ABORT;
        }
    }
    
    function sendFunds() 
	payable
    public{
        
        require(msg.sender==Target,"sender is not required actor");
		require(CurrentState==Enums.State.REQUEST,"State is not appropriate");
        require(msg.value >= OfferedFunds,"send at least the offered funds");
		
		CurrentState = Enums.State.PROOF;
    }
    
    
    function uploadProof(string memory _Proof) 
    public{
        
        require(msg.sender==Mitigator,"sender is not required actor");
        require(CurrentState==Enums.State.REQUEST,"State is not appropriate");
        
        Proof = _Proof;
		CurrentState = Enums.State.RATE_T;
    }
    
    function ratingByTarget(uint _Rating) 
    public{
        
        require(msg.sender==Target,"sender is not required actor");
        require(CurrentState==Enums.State.PROOF,"State is not appropriate");

        TargetRating = Enums.Rating(_Rating);
        
		if(bytes(Proof).length>0){
			return endProcess();
        }
		CurrentState = Enums.State.RATE_M;
    }
    
    function ratingByMitigator(uint _Rating) 
    public{
        
		require(msg.sender==Mitigator,"sender is not required actor");
		require(CurrentState==Enums.State.RATE_M,"State is not appropriate");
		
        MitigatorRating = Enums.Rating(_Rating);
        
		return endProcess();
    }
	
	function endProcess() private{
		address payable owner;
		Enums.State stateToSet;
		
        (owner,stateToSet) = evaluate();
		
		if(owner!=address(0)){
			owner.transfer(address(this).balance);
		}
		EndTime = now;
	}
	
	 function evaluate() private view returns (address payable,Enums.State){    
        if(bytes(Proof).length>0){
			if(TargetRating==Enums.Rating.POS){
				return satisfied();
			}else if(TargetRating==Enums.Rating.NEG){
				return dissatisfied();
			}else{
				return selfish();
			}
        }else{
            if(TargetRating==Enums.Rating.NEG){
				return(Target,Enums.State.COMPLETE);
            }else{
                return(address(0),Enums.State.ABORT);
            }
        }
    }
    
    function satisfied() private view returns (address payable,Enums.State){    
        if(MitigatorRating==Enums.Rating.POS){
			return(Mitigator,Enums.State.COMPLETE);
        }else{
            return(address(0),Enums.State.ABORT);
        }
    }
    
    function selfish() private view returns (address payable,Enums.State){    
        if(MitigatorRating==Enums.Rating.POS){
            return(Mitigator,Enums.State.COMPLETE);
        }else{
            return(address(0),Enums.State.ABORT);
        }
    }
    
    function dissatisfied() private view returns (address payable,Enums.State){    
        if(MitigatorRating==Enums.Rating.POS){
            return(address(0),Enums.State.ESCALATE);
        }else{
            return(Target,Enums.State.COMPLETE);
        }
    }

}