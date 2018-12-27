pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol";

contract ERC1 is StandardToken {
    string public name;
    string public symbol;
    uint8 public decimals = 18;

    constructor(
        string _name,
        string _symbol,
        uint256 _totalSupply
    )
        public
    {
        name = _name;
        symbol = _symbol;
        totalSupply_ = _totalSupply;
        balances[msg.sender] = _totalSupply;
    }

}
