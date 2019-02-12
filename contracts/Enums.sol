pragma solidity ^0.5.0;

contract  Enums {

	enum State {REQUEST,APPROVE,FUNDING,PROOF,RATE_T,RATE_M,COMPLETE,ABORT,ESCALATE}
    enum Rating {NEG,NA,POS}
}