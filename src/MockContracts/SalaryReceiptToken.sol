// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)
pragma solidity ^0.8.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract SalaryReceiptToken is ERC20, Ownable {
    /*
    The ERC20 deployed will be owned by the others contracts of the protocol, specifically by
    MasterMagpie and WombatStaking, forbidding the misuse of these functions for nefarious purposes
    */

    error OnlyWhitelisted();
    
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) Ownable(msg.sender) {} 

    mapping(address=>bool) whitelistedForTransfer;

    function mint(address account, uint256 amount) external virtual onlyOwner {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external virtual onlyOwner {
        _burn(account, amount);
    }

    function transfer(address to, uint256 value) public override returns (bool) {
        if(!(whitelistedForTransfer[msg.sender] || whitelistedForTransfer[to]))
            revert OnlyWhitelisted();

        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
        if(!(whitelistedForTransfer[from] || whitelistedForTransfer[to]))
            revert OnlyWhitelisted();

        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    function whitelistForTransfer(address user, bool whitelist) external onlyOwner {
        whitelistedForTransfer[user] = whitelist;
    }

    function bringBackReceipt(address user, uint256 amount) external onlyOwner {
        _transfer(user, owner(), amount);

    }

    function batchTransfer(address[] memory users, uint256[] memory amounts) external onlyOwner {
        for (uint256 i = 0; i < users.length; i++) {
            _transfer(owner(), users[i], amounts[i]);
        }
    }

    function batchBringBackReceipt(address[] memory users, uint256[] memory amounts) external onlyOwner {
        for (uint256 i = 0; i < users.length; i++) {
            _transfer(users[i], owner(), amounts[i]);
        }
    }
    
}