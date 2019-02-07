pragma solidity ^0.5.0;

import "./IState.sol";

contract StateStart is IState{
    
	constructor(address payable _data) IState(_data) public payable {}
	
    function canAdvance() public returns(bool){
        require(aborted!= true,"Process has been aborted");
        //require(getActorOfState().getOwner() == caller,"Error proceed in Start");
        return true;
    }
    
    function execute() public{
        if(!canAdvance()){
            revert("Can't advance");
        }
    }
    
    function getActorOfState() public view returns(address){return IData(data).getTarget();}
    
}