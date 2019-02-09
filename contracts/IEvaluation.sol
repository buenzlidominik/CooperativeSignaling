pragma solidity ^0.5.0;

import "./Enums.sol";

contract  IEvaluation {

	address payable internal TargetAddress;
	address payable internal MitigatorAddress;
	
	constructor(address payable _TargetAddress,address payable _MitigatorAddress) public{
		TargetAddress= _TargetAddress;
		MitigatorAddress= _MitigatorAddress;
	}

    function evaluate(Enums.Rating TargetRating, Enums.Rating MitigatorRating) public view returns (address payable,Enums.State);
}