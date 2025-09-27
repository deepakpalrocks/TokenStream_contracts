// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { ERC4626 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IStreamRewarder } from "./interfaces/IStreamRewarder.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Vault is ERC4626 {

    address public immutable rewarder;

    constructor(
        IERC20 _token, 
        string memory vaultName, 
        string memory vaultSymbol, 
        address _rewarder
    ) ERC4626(_token) ERC20(vaultName, vaultSymbol) {
        rewarder = _rewarder;
    }

    function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal override {

        IStreamRewarder(rewarder).updateFor(receiver);
        SafeERC20.safeTransferFrom(IERC20(asset()), caller, address(this), assets);
        _mint(receiver, shares);

        emit Deposit(caller, receiver, assets, shares);
    }

    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) internal override {
        if (caller != owner) {
            _spendAllowance(owner, caller, shares);
        }

        IStreamRewarder(rewarder).updateFor(receiver);
        _burn(owner, shares);
        SafeERC20.safeTransfer(IERC20(asset()), receiver, assets);

        emit Withdraw(caller, receiver, owner, assets, shares);
    }

}
