pragma solidity ^0.5.0;

import "./IActor.sol";

contract  ProcessData {

    enum State {REQUEST,APPROVE,FUNDING,PROOF,TRATE,MRATE,COMPLETE,ABORT,ESCALATE}
    enum Rating {REJ,NA,ACK}
    
    IActor Target;
    IActor Mitigator;
    IActor NextActor;
    uint private PotentialFunds = 0;
    uint private Funds = 0;
    uint private DeadlineInterval;
    uint private Deadline;
    
    State CurrentState; 
    string Proof;
    string ListOfAddresses;
    Rating TargetRating;
    Rating MitigatorRating;
	
    constructor (address _Target,address _Mitigator,uint Interval,uint256 _PotentialFunds,string memory _ListOfAddresses) public payable
    {
        PotentialFunds = _PotentialFunds;
        Target = IActor(_Target);
        Mitigator = IActor(_Mitigator);
        NextActor = Mitigator;
        CurrentState = State.APPROVE;
        DeadlineInterval = Interval;
        ListOfAddresses=_ListOfAddresses;
    }

    function receiveFunds(uint256 amount) public payable{    
        Funds = amount;
    }
    
    function transferFunds(IActor receiver) public {    
        receiver.getOwner().transfer(Funds);
    }
    
    function() payable external {}
  
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
    returns (uint){
        return Funds;
    }
    
    function getPotentialFunds() 
    public view
    returns (uint){
        return Funds;
    }
    
    function getTargetRating() 
    public view
    returns (Rating){
        return TargetRating;
    }
    
    function getMitigatorRating() 
    public view
    returns (Rating){
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
        Deadline = now+ (DeadlineInterval * 1 seconds);
    }
    
    function setNextActor(IActor _NextActor) 
    public {
        NextActor = _NextActor;
    }

    function setProof(string memory _Proof) 
    public{
        Proof = _Proof;
    }
    
    function setState(State state) 
    public{
        CurrentState = state;
    }
    
    function setTargetRating(Rating rating) 
    public{
        TargetRating = rating;
    }
    
    function setMitigatorRating(Rating rating) 
    public{
        MitigatorRating = rating;
    }
    
    function isProofProvided()
    public view
    returns(bool){
        if(bytes(Proof).length >0){return true;}
        return false;
    }
}
