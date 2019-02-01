pragma solidity ^0.5.0;

import "./ProcessData.sol";

contract  Evaluation {

    function evaluate(ProcessData Data) public payable  returns (ProcessData){    
        if(Data.isProofProvided()){
            evaluationWithProof(Data);
        }else{
            evaluationWithoutProof(Data);
        }
        
        return Data;
    }
    
    function evaluationWithoutProof(ProcessData Data) public payable  {    
        if(Data.getTargetRating()==ProcessData.Rating.REJ){
                Data.transferFunds(Data.getTarget());
                Data.setState(ProcessData.State.COMPLETE);
            }else{
                Data.setState(ProcessData.State.ABORT);
            }
    }
    
    function evaluationWithProof(ProcessData Data) public payable  {    
        if(Data.getTargetRating()==ProcessData.Rating.ACK){
            evaluationWithProofAcknowledged(Data);
        }else if(Data.getTargetRating()==ProcessData.Rating.REJ){
            evaluationWithProofRejected(Data);
        }else{
            evaluationWithProofSelfish(Data);
        }
    }
    
    function evaluationWithProofAcknowledged(ProcessData Data) public payable  {    
        if(Data.getMitigatorRating()==ProcessData.Rating.ACK){
            Data.transferFunds(Data.getMitigator());
            Data.setState(ProcessData.State.COMPLETE);
        }else{
            Data.setState(ProcessData.State.ABORT);
        }
    }
    
    function evaluationWithProofSelfish(ProcessData Data) public payable  {    
        if(Data.getMitigatorRating()==ProcessData.Rating.ACK){
            Data.transferFunds(Data.getMitigator());
            Data.setState(ProcessData.State.COMPLETE);
        }else{
            Data.setState(ProcessData.State.ABORT);
        }
    }
    
    function evaluationWithProofRejected(ProcessData Data) public payable  {    
        if(Data.getMitigatorRating()==ProcessData.Rating.ACK){
            Data.transferFunds(Data.getTarget());
            Data.setState(ProcessData.State.ESCALATE);
        }else{
            Data.transferFunds(Data.getTarget());
            Data.setState(ProcessData.State.COMPLETE);
        }
    }
}