// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Jubril is ERC20, Ownable {
    constructor(address initialOwner)
        ERC20("Jubril", "jb")
        Ownable(initialOwner)
        
    {
        _mint(initialOwner, 100000 * 10 ** 18);
    }


    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
