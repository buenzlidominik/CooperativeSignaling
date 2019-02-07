pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "./IData.sol";
import "./Enums.sol";
import "./IState.sol";
import "./StateStart.sol";
import "./StateFunding.sol";
import "./StateRatingByMitigator.sol";
import "./StateEvaluation.sol";
import "./StateApprove.sol";
import "./StateProof.sol";
import "./StateRatingByTarget.sol";

contract Process{
    
    IState private State;
    IData data;
    constructor() public payable{}
    
    function init(address payable T,address payable M,uint Interval,string memory listOfAddresses,uint256 amountOfAddresses) public returns(address){
        data = new IData(T,M,Interval,listOfAddresses,amountOfAddresses);
		State =new StateStart(address(data));
        State.execute();
		State = new StateApprove(address(data));
    }
    
    function approve(bool descision) 
    public{
        
        State.execute(descision);
		State = new StateFunding(address(data));
	}
    
    function sendFunds() 
    public{
		address(data).transfer(address(this).balance);
        State.execute();
		State = new StateProof(address(data));
    }
    
    function uploadProof(string memory value) 
    public{
        
        State.execute(value);
		State = new StateRatingByTarget(address(data));
    }
    
    function rateByTarget(uint256 value) 
    public{
        
        State.execute(value);
		State = new StateRatingByMitigator(address(data));
    }
    
    function rateByMitigator(uint256 value) 
    public{
        
        State.execute(value);
    }
    
    function() payable external {
	}
    
    function getState() 
    public view
    returns (IState){
        return State;
    }
    
}