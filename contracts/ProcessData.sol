pragma solidity ^0.5.0;

import "./IActor.sol";
import "./IEvaluation.sol";
import "./EvaluationWithProof.sol";
import "./EvaluationWithoutProof.sol";
import "./Enums.sol";

contract  ProcessData {

    IActor Target;
    IActor Mitigator;
    IActor NextActor;
	address private OwnedByContract;
    uint256 private OfferedFunds = 0;
    uint256 private DeadlineInterval;
    uint256 private Deadline;
	uint256 private StartTime;
	uint256 private EndTime;
	event Received(uint256 value);
	
    Enums.State private CurrentState; 
    string private Proof;
    string private ListOfAddresses;
    Enums.Rating private TargetRating;
    Enums.Rating private MitigatorRating;
	
    constructor (address _Target,address _Mitigator,uint Interval,uint256 _OfferedFunds,string memory _ListOfAddresses) public payable
    {
		OwnedByContract = msg.sender;
        OfferedFunds = _OfferedFunds;
        Target = IActor(_Target);
        Mitigator = IActor(_Mitigator);
        NextActor = Mitigator;
		StartTime = now;
        CurrentState = Enums.State.APPROVE;
        DeadlineInterval = Interval;
        ListOfAddresses=_ListOfAddresses;
    }
    
    function transferFunds(IActor receiver) public {   
		require(msg.sender==OwnedByContract,"Action can only be performed by the owning contract");
        receiver.getOwner().transfer(address(this).balance);
    }
    
    function() payable external {
		require(msg.value >= OfferedFunds,"Please provide at least the funds you initially offered");
		emit Received(msg.value);
	}
	
    function getNextActor() public view returns (IActor){
        return NextActor;
    }

    function getTarget() public view returns (IActor){
        return Target;
    }
	
	//Method is used to Instantiate the evaluation and get the address of the fund receiver and the end state that needs to be set
	function executeEvaluation() public{
		
		require(msg.sender==OwnedByContract,"Action can only be performed by the owning contract");
		address actor;
		Enums.State stateToSet;
		
		IEvaluation _Evaluation;
		
		if(isProofProvided()){
			_Evaluation = new EvaluationWithProof(address(Target),address(Mitigator));
		}else{
			_Evaluation = new EvaluationWithoutProof(address(Target),address(Mitigator));
		}

        (actor,stateToSet) = _Evaluation.evaluate(getTargetRating(), getMitigatorRating());
		
		if(actor!=address(0)){
			transferFunds(IActor(actor));
		}
		endProcess(stateToSet);
    }
    
    function getDeadline() public view returns (uint){
        return Deadline;
    }

    function getMitigator() public view returns (IActor){
        return Mitigator;
    }

    function getFunds() public view returns (uint256){
        return address(this).balance;
    }
    
    function getOfferedFunds() public view returns (uint){
        return OfferedFunds;
    }
    
    function getTargetRating() public view returns (Enums.Rating){
        return TargetRating;
    }
    
    function getMitigatorRating() public view returns (Enums.Rating){
        return MitigatorRating;
    }
    
    function getState() public view returns (uint){
        return uint(CurrentState);
    }
    
    function getProof() public view returns (string memory){
        return Proof;
    }
	
	function getStartTime() public view returns (uint256){
        return StartTime;
    }
	
	function getStartAndEndTime() public view returns (uint256,uint256){
		require(getState()>=uint(Enums.State.COMPLETE),"Process not completed, no endtime given");
        return (StartTime,EndTime);
    }
    
	function getListOfAddresses() public view returns (string memory){
        return ListOfAddresses;
    }
	
	function endProcess(Enums.State _State) public {
		require(msg.sender==OwnedByContract,"Action can only be performed by the owning contract");
		CurrentState = _State;
		NextActor = Target;
		EndTime= now;
    }

    function setProof(string memory _Proof) public{
		require(msg.sender==OwnedByContract,"Action can only be performed by the owning contract");
		require(bytes(_Proof).length > 0,"Empty string cannot be accepted as a proof");
        Proof = _Proof;
    }
	
	function advanceState() public {
		require(msg.sender==OwnedByContract,"Action can only be performed by the owning contract");
		
		if(CurrentState>=Enums.State.FUNDING){
			Deadline = (now+ (DeadlineInterval * 1 seconds));
		}
		
		//If the current next actor is target, the next actor after advancing should be the mitigator
		if(getNextActor()==getTarget()){
			NextActor = getMitigator();
		}else{
			NextActor = getTarget();				
		}
		
		if(CurrentState == Enums.State.MRATE){
			executeEvaluation();
		}else{
			//advance the state plus 1
			uint nextState = uint(CurrentState)+1;
			setState(Enums.State(nextState));
		}
	}
    
    function setState(Enums.State state) private{
        CurrentState = state;
    }
    
    function setTargetRating(Enums.Rating rating) public{
		require(msg.sender==OwnedByContract,"Action can only be performed by the owning contract");
        TargetRating = rating;
    }
    
    function setMitigatorRating(Enums.Rating rating) public{
		require(msg.sender==OwnedByContract,"Action can only be performed by the owning contract");
        MitigatorRating = rating;
    }
    
    function isProofProvided() public view returns(bool){
        if(bytes(Proof).length >0){return true;}
        return false;
    }
}
