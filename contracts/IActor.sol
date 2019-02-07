pragma solidity ^0.5.0;

contract IActor {
    
    address payable private Owner;
    uint private PricePerUnit;
    string private Network;

    constructor (address payable _Owner,uint256 price, string memory net) 
	payable
    public
    {
        Owner = _Owner;
        PricePerUnit = price;
        Network = net;
    }

    function getOwner() 
    external view
    returns (address payable){
        return Owner;
    }
	
	function() payable external {
		Owner.transfer(address(this).balance);
	}

    function isOfferAcceptable(uint256 offer,uint amountOfAddresses) 
    public view
    returns (bool){
        require(offer >= amountOfAddresses*PricePerUnit,"Offer was too low, please provide more funds.");
        return true;
    }
    
    function getPricePerUnit() 
    public view
    returns (uint){
        return PricePerUnit;
    }

    function getNetwork() 
    public view
    returns (string memory){
        return Network;
    }

}