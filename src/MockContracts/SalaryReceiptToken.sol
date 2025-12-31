// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)
pragma solidity ^0.8.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { StreamRewarder } from "../StreamRewarder.sol";

contract SalaryReceiptToken is ERC20, Ownable {
    using SafeERC20 for IERC20Metadata;

    error OnlyWhitelisted();

    address public rewarder;
    
    constructor(string memory name_, string memory symbol_, address _rewarder) ERC20(name_, symbol_) {
        rewarder = _rewarder;
    } 

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

    // rewards are calculated based on user's receipt token balance, so reward should be updated on master penpie before transfer
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        StreamRewarder(rewarder).updateFor(from);
        StreamRewarder(rewarder).updateFor(to);
    }

    // rewards are calculated based on user's receipt token balance, so balance should be updated on master penpie before transfer
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        StreamRewarder(rewarder).updateFor(from);
        StreamRewarder(rewarder).updateFor(to);
    }
    
}