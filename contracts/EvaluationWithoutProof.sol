pragma solidity ^0.5.0;

import "./Enums.sol";
import "./IEvaluation.sol";

contract EvaluationWithoutProof is IEvaluation{

	address internal TargetAddress;
	address internal MitigatorAddress;
	
	constructor(address _TargetAddress,address  _MitigatorAddress) public{
		TargetAddress= _TargetAddress;
		MitigatorAddress= _MitigatorAddress;
	}

    function evaluate(Enums.Rating TargetRating, Enums.Rating MitigatorRating) public view returns (address ,Enums.State){ 
		
		//used to silence warning for MitigatorRating
		if(MitigatorRating==Enums.Rating.POS){	}
		
		if(TargetRating==Enums.Rating.NEG){
			return(TargetAddress,Enums.State.COMPLETE);
        }else{
			return(address(0),Enums.State.ABORT);
		}
    }
   
}