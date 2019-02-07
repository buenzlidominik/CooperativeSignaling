pragma solidity ^0.5.0;

import "./IState.sol";

contract StateApprove is IState{
    
	string public Statename = "Approve";
	
	constructor(address payable _data) IState(_data) public payable {}
	
    function canAdvance() public returns(bool){
        require(aborted!= true,"Process aborted");
        //require(getActorOfState().getOwner() == caller,"Error proceed in approve");
        return true;
    }
    
    function execute(bool value) public{
        if(!canAdvance()){
            revert("Can't advance");
        }
        if(value==false){
            abort();
        }
    }
    
    function getActorOfState() public view returns(address){return IData(data).getMitigator();}

}