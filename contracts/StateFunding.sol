pragma solidity ^0.5.0;

import "./IState.sol";

contract StateFunding is IState{

	string public Statename = "Funding";

	constructor(address payable _data) IState(_data) public payable {}
	
    function execute() public{
        if(!canAdvance()){
            revert("Can't advance");
        }
    }
	
    function getActorOfState() public view returns(address){return IData(data).getTarget();}

}