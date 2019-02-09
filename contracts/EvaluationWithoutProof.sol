pragma solidity ^0.5.0;

import "./Enums.sol";
import "./IEvaluation.sol";

contract EvaluationWithoutProof is IEvaluation{

	constructor(address _TargetAddress,address _MitigatorAddress) public IEvaluation(_TargetAddress,_MitigatorAddress){}

    function evaluate(Enums.Rating TargetRating, Enums.Rating MitigatorRating) public view returns (address,Enums.State){ 
		
		//used to silence warning for MitigatorRating
		if(MitigatorRating==Enums.Rating.NEG){	}
		
		if(TargetRating==Enums.Rating.NEG){
			return(TargetAddress,Enums.State.COMPLETE);
        }else{
			return(address(0),Enums.State.ABORT);
		}
    }
   
}