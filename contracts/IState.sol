pragma solidity ^0.5.0;

import "./IData.sol";
import "./IActor.sol";
import "./Enums.sol";

interface IState {
            
    function execute() external returns(Enums.StateType);
    function execute(bool value) external returns(Enums.StateType);
    function execute(uint256 value) external returns(Enums.StateType);
    function execute(string calldata value) external returns(Enums.StateType);
    
    function getOwnerOfState() external view returns(address payable);
	
	function getStateType() external view returns(Enums.StateType);
}