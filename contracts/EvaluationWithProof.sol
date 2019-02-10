pragma solidity ^0.5.0;

import "./Enums.sol";
import "./IEvaluation.sol";

contract  EvaluationWithProof is IEvaluation{
	
	address payable internal TargetAddress;
	address payable internal MitigatorAddress;
	
	constructor(address payable _TargetAddress,address payable _MitigatorAddress) public{
		TargetAddress= _TargetAddress;
		MitigatorAddress= _MitigatorAddress;
	}

    function evaluate(Enums.Rating TargetRating, Enums.Rating MitigatorRating) public view returns (address payable,Enums.StateType){    
        if(TargetRating==Enums.Rating.ACK){
            return acknowledged(MitigatorRating);
        }else if(TargetRating==Enums.Rating.REJ){
            return rejected(MitigatorRating);
        }else{
            return selfish(MitigatorRating);
        }
    }

    function acknowledged(Enums.Rating MitigatorRating) public view returns (address payable,Enums.StateType){    
        if(MitigatorRating==Enums.Rating.ACK){
			return(MitigatorAddress,Enums.StateType.COMPLETE);
        }else{
            return(address(0),Enums.StateType.ABORT);
        }
    }
    
    function selfish(Enums.Rating MitigatorRating) public view returns (address payable,Enums.StateType){    
        if(MitigatorRating==Enums.Rating.REJ){
            return(MitigatorAddress,Enums.StateType.COMPLETE);
        }else{
            return(address(0),Enums.StateType.ABORT);
        }
    }
    
    function rejected(Enums.Rating MitigatorRating) public view returns (address payable,Enums.StateType){    
        if(MitigatorRating==Enums.Rating.REJ){
            return(address(0),Enums.StateType.ESCALATE);
        }else{
            return(TargetAddress,Enums.StateType.COMPLETE);
        }
    }
}