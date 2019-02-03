pragma solidity ^0.5.0;

import "./IActor.sol";
import "./Evaluation.sol";
import "./Enums.sol";

contract  ProcessData {

    IActor Target;
    IActor Mitigator;
    IActor NextActor;
	address private OwnedByContract;
    uint private OfferedFunds = 0;
    uint private DeadlineInterval;
    uint private Deadline;
    Evaluation private _Evaluation;
	event Received(uint256 value);
	
    Enums.State CurrentState; 
    string Proof;
    string ListOfAddresses;
    Enums.Rating TargetRating;
    Enums.Rating MitigatorRating;
	
    constructor (address _Target,address _Mitigator,uint Interval,uint256 _OfferedFunds,string memory _ListOfAddresses) public payable
    {
		OwnedByContract = msg.sender;
        OfferedFunds = _OfferedFunds;
        Target = IActor(_Target);
        Mitigator = IActor(_Mitigator);
        NextActor = Mitigator;
        CurrentState = Enums.State.APPROVE;
        DeadlineInterval = Interval;
        ListOfAddresses=_ListOfAddresses;
    }
    
    function transferFunds(IActor receiver) public {   
		//require(msg.sender==OwnedByContract,"Funds can only be transferred by the owning contract");
        receiver.getOwner().transfer(address(this).balance);
    }
    
    function() payable external {
		require(msg.value >= OfferedFunds,"Please provide at least the funds you initially offered");
		emit Received(msg.value);
	}
  
    function getAddress() 
    public view
    returns (address payable){
        return address(this);
    }
    
    function getNextActor() 
    public view
    returns (IActor){
        return NextActor;
    }

    function getTarget() 
    public view
    returns (IActor){
        return Target;
    }
	
	function executeEvaluation() 
    public{
		address actor;
		Enums.State stateToSet;
		_Evaluation = new Evaluation(this.getAddress(),Target.getAddress(),Mitigator.getAddress());
		
        (actor,stateToSet) = _Evaluation.evaluate(isProofProvided(),getTargetRating(), getMitigatorRating());
		
		if(actor!=address(0)){
			transferFunds(IActor(actor));
		}
		setState(stateToSet);
    }
    
    function getDeadline() 
    public view
    returns (uint){
        return Deadline;
    }

    function getMitigator() 
    public view
    returns (IActor){
        return Mitigator;
    }

    function getFunds() 
    public view
    returns (uint256){
        return address(this).balance;
    }
    
    function getOfferedFunds() 
    public view
    returns (uint){
        return OfferedFunds;
    }
    
    function getTargetRating() 
    public view
    returns (Enums.Rating){
        return TargetRating;
    }
    
    function getMitigatorRating() 
    public view
    returns (Enums.Rating){
        return MitigatorRating;
    }
    
    function getState() 
    public view
    returns (uint){
        return uint(CurrentState);
    }
    
    function getProof() 
    public view
    returns (string memory){
        return Proof;
    }
    
	function getListOfAddresses() 
    public view
    returns (string memory){
        return ListOfAddresses;
    }
	
    function setNextDeadline() 
    public {
		require(msg.sender==OwnedByContract,"Action can only be performed by the owning contract");
        Deadline = now+ (DeadlineInterval * 1 seconds);
    }
    
    function setNextActor(IActor _NextActor) 
    public {
		//require(msg.sender==OwnedByContract,"Action can only be performed by the owning contract");
        NextActor = _NextActor;
    }

    function setProof(string memory _Proof) 
    public{
		//require(msg.sender==OwnedByContract,"Action can only be performed by the owning contract");
		require(bytes(_Proof).length > 0,"Empty string cannot be accepted as a proof");
        Proof = _Proof;
    }
    
    function setState(Enums.State state) 
    public{
		//require(msg.sender==OwnedByContract,"Action can only be performed by the owning contract");
        CurrentState = state;
    }
    
    function setTargetRating(Enums.Rating rating) 
    public{
		//require(msg.sender==OwnedByContract,"Action can only be performed by the owning contract");
        TargetRating = rating;
    }
    
    function setMitigatorRating(Enums.Rating rating) 
    public{
		//require(msg.sender==OwnedByContract,"Action can only be performed by the owning contract");
        MitigatorRating = rating;
    }
    
    function isProofProvided()
    public view
    returns(bool){
        if(bytes(Proof).length >0){return true;}
        return false;
    }
}
