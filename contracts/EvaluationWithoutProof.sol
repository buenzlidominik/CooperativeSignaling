pragma solidity ^0.5.0;

import "./Enums.sol";
import "./IEvaluation.sol";

contract EvaluationWithoutProof is IEvaluation{

	constructor(address payable _TargetAddress,address payable _MitigatorAddress) public IEvaluation(_TargetAddress,_MitigatorAddress){}

    function evaluate(Enums.Rating TargetRating, Enums.Rating MitigatorRating) public view returns (address payable,Enums.State){ 
		
		//used to silence warning for MitigatorRating
		if(MitigatorRating==Enums.Rating.ACK){	}
		
		if(TargetRating==Enums.Rating.ACK){
			return(TargetAddress,Enums.State.COMPLETE);
        }else{
			return(address(0),Enums.State.ABORT);
		}
    }
   
}