pragma solidity ^0.5.0;

import "./Enums.sol";
import "./IEvaluation.sol";

contract EvaluationWithoutProof is IEvaluation{

	address payable internal TargetAddress;
	address payable internal MitigatorAddress;
	
	constructor(address payable _TargetAddress,address payable _MitigatorAddress) public{
		TargetAddress= _TargetAddress;
		MitigatorAddress= _MitigatorAddress;
	}

    function evaluate(Enums.Rating TargetRating, Enums.Rating MitigatorRating) public view returns (address payable,Enums.StateType){ 
		
		//used to silence warning for MitigatorRating
		if(MitigatorRating==Enums.Rating.ACK){	}
		
		if(TargetRating==Enums.Rating.ACK){
			return(TargetAddress,Enums.StateType.COMPLETE);
        }else{
			return(address(0),Enums.StateType.ABORT);
		}
    }
   
}