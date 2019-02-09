pragma solidity ^0.5.0;

import "./Enums.sol";

contract  IEvaluation {

	address internal TargetAddress;
	address internal MitigatorAddress;
	
	constructor(address _TargetAddress,address _MitigatorAddress) public{
		TargetAddress= _TargetAddress;
		MitigatorAddress= _MitigatorAddress;
	}

    function evaluate(Enums.Rating TargetRating, Enums.Rating MitigatorRating) public view returns (address,Enums.State);
}