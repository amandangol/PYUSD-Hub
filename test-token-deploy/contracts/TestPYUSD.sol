// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestPYUSD is ERC20 {
    uint8 private _decimals = 6;  // PYUSD has 6 decimals

    constructor(uint256 initialSupply) ERC20("Test PYUSD", "TPYUSD") {
        _mint(msg.sender, initialSupply * (10 ** decimals()));
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
}