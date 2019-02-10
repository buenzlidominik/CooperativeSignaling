pragma solidity ^0.5.0;

import "./IData.sol";
import "./Enums.sol";
import "./IState.sol";
import "./StateFactory.sol";

contract Process{
    
    IState private State;
    IData Data;
	bool Finish = false;
	event ReceivedProcess(uint256 value);
	
    constructor() public payable{}
    
    function init(address payable _Target,address payable _Mitigator,uint256 _Interval,string memory _ListOfAddresses,uint256 _OfferedFunds) public{
        Data = new IData(_Target,_Mitigator,_Interval,_ListOfAddresses,_OfferedFunds);
		State =StateFactory.create(Enums.StateType.REQUEST,address(Data));
        State.execute();
		State =StateFactory.create(Enums.StateType.APPROVE,address(Data));
    }
    
    function approve(bool descision) 
    public{
        
        State.execute(descision);
		State =StateFactory.create(Enums.StateType.FUNDING,address(Data));
	}
    
    function sendFunds() 
    public{
		address(Data).transfer(address(this).balance);
        State.execute();
		State = StateFactory.create(Enums.StateType.PROOF,address(Data));
    }
    
    function uploadProof(string memory value) 
    public{
        
        State.execute(value);
		State =StateFactory.create(Enums.StateType.RATE_T,address(Data));
    }
    
    function rateByTarget(uint256 value) 
    public{
        
        State.execute(value);
		State =StateFactory.create(Enums.StateType.RATE_M,address(Data));
    }
    
    function rateByMitigator(uint256 value) 
    public{
        
        State.execute(value);
		State =StateFactory.create(Enums.StateType.EVALUATION,address(Data));
		Finish = true;
    }
    
    function() payable external {
		emit ReceivedProcess(msg.value);
	}
    
    function getState() 
    public view
    returns (address){
        return address(State);
    }
	
	function isFinished() 
    public view
    returns (bool){
        return Finish;
    }
	
	function getData() 
    public view
    returns (address payable){
        return address(Data);
    }
    
}