// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.4.23;

import "openzeppelin-solidity/contracts/token/ERC20/DetailedERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol";
import "openzeppelin-solidity/contracts/token/ERC20/MintableToken.sol";
import "openzeppelin-solidity/contracts/token/ERC20/PausableToken.sol";

// Now we want to add some more behavior to our token. First, we want to make the token "mintable", which means we want to be able to create new tokens. This will allow us to create new tokens in the crowdsale, instead of having a fixed total supply from the beginning. Next, we want to make our token "pausable". This will allow us to freeze token transfers during the crowdsale so that investors cannot dump them while other people are still buying them. 

contract Token is MintableToken, PausableToken, DetailedERC20 {
    constructor(string name, string symbol, uint8 decimals)
        DetailedERC20(name, symbol, decimals) public {

        }
}