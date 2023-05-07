// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ICOT is ERC20 {
    constructor() ERC20("ICOT", "ICOT") {
        _mint(msg.sender, 10000000 * 1e18);
    }
}
