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
	Enums.StateType currentState;
	
    constructor() public payable{}
    
    function init(address payable _Target,address payable _Mitigator,uint256 _Interval,string memory _ListOfAddresses,uint256 _OfferedFunds) public{
        Data = new IData(_Target,_Mitigator,_Interval,_ListOfAddresses,_OfferedFunds);
		State =StateFactory.create(Enums.StateType.REQUEST,address(Data));
        currentState =State.execute();
		State =StateFactory.create(currentState,address(Data));
    }
    
    function approve(bool descision) 
    public{
        require(currentState==Enums.StateType.APPROVE,"State is not correct");
        currentState = State.execute(descision);
		State =StateFactory.create(currentState,address(Data));
	}
    
    function sendFunds() 
    public{
		require(currentState==Enums.StateType.FUNDING,"State is not correct");
		address(Data).transfer(address(this).balance);
        currentState = State.execute();
		State = StateFactory.create(currentState,address(Data));
    }
    
    function uploadProof(string memory value) 
    public{
        require(currentState==Enums.StateType.PROOF,"State is not correct");
        currentState = State.execute(value);
		State =StateFactory.create(currentState,address(Data));
    }
    
    function rateByTarget(uint256 value) 
    public{
        require(currentState==Enums.StateType.RATE_T,"State is not correct");
        currentState = State.execute(value);
		State =StateFactory.create(currentState,address(Data));
		if(currentState==Enums.StateType.EVALUATION){
			currentState = State.execute();
			endProcess();
		}
    }
    
    function rateByMitigator(uint256 value) 
    public{
        require(currentState==Enums.StateType.RATE_M,"State is not correct");
        currentState = State.execute(value);
		State =StateFactory.create(currentState,address(Data));
		currentState= State.execute();
		endProcess();
    }
	
	function endProcess() private {
		State =StateFactory.create(currentState,address(Data));
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