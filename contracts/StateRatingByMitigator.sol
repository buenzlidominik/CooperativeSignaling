pragma solidity ^0.5.0;

import "./IState.sol";

contract StateRatingByMitigator is IState{

	constructor(address payable _data) IState(_data) public payable {}
	
    function execute(uint256 value) public{
        if(!canAdvance()){
            revert("Can't advance");
        }
        IData(data).setMitigatorRating(Enums.Rating(value));
    }

    function getActorOfState() public view returns(address){return IData(data).getMitigator();}
    
}