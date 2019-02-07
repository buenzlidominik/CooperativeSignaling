pragma solidity ^0.5.0;

import "./IState.sol";

contract StateProof is IState{

	constructor(address payable _data) IState(_data) public payable {}
	
    function execute(string memory value) public{
        if(!canAdvance()){
            revert("Can't advance");
        }
        IData(data).setProof(value);
    }
    
    function getActorOfState() public view returns(address){return IData(data).getMitigator();}

}