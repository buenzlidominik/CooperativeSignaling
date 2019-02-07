pragma solidity ^0.5.0;

import "./IState.sol";

contract StateEvaluation is IState{
	
	address payable TargetAddress = IData(data).getTarget();
	address payable MitigatorAddress = IData(data).getMitigator();
	
	constructor(address payable _data) IState(_data) public payable {}
	
    function execute() public{
        if(!canAdvance()){
            revert("Can't advance");
        }
		
		address payable actor;
		Enums.State stateToSet;
		
        (actor,stateToSet) = evaluate(true,IData(data).getTargetRating(),IData(data).getMitigatorRating());
	
		if(actor!=address(0)){
			IData(data).transferFunds(actor);
		}
        abort();
    }
    
	function evaluate(bool _ProofWasProvided, Enums.Rating TargetRating, Enums.Rating MitigatorRating) public view returns (address payable,Enums.State){    
        if(_ProofWasProvided){
            return evaluationWithProof(TargetRating,MitigatorRating);
        }else{
            return evaluationWithoutProof(TargetRating);
        }
    }
    
    function evaluationWithoutProof(Enums.Rating TargetRating) public view returns (address payable,Enums.State){    
        if(TargetRating==Enums.Rating.REJ){
				return(TargetAddress,Enums.State.COMPLETE);
            }else{
                return(address(0),Enums.State.ABORT);
            }
    }
    
    function evaluationWithProof(Enums.Rating TargetRating, Enums.Rating MitigatorRating) public view returns (address payable,Enums.State){    
        if(TargetRating==Enums.Rating.ACK){
            return evaluationWithProofAcknowledged(MitigatorRating);
        }else if(TargetRating==Enums.Rating.REJ){
            return evaluationWithProofRejected(MitigatorRating);
        }else{
            return evaluationWithProofSelfish(MitigatorRating);
        }
    }
    
    function evaluationWithProofAcknowledged(Enums.Rating MitigatorRating) public view returns (address payable,Enums.State){    
        if(MitigatorRating==Enums.Rating.ACK){
			return(MitigatorAddress,Enums.State.COMPLETE);
        }else{
            return(address(0),Enums.State.ABORT);
        }
    }
    
    function evaluationWithProofSelfish(Enums.Rating MitigatorRating) public view returns (address payable,Enums.State){    
        if(MitigatorRating==Enums.Rating.ACK){
            return(MitigatorAddress,Enums.State.COMPLETE);
        }else{
            return(address(0),Enums.State.ABORT);
        }
    }
    
    function evaluationWithProofRejected(Enums.Rating MitigatorRating) public view returns (address payable,Enums.State){    
        if(MitigatorRating==Enums.Rating.ACK){
            return(address(0),Enums.State.ESCALATE);
        }else{
            return(TargetAddress,Enums.State.COMPLETE);
        }
    }
    function getActorOfState() public view returns(address){return IData(data).getTarget();}

}