// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {StreamRewarder} from "../src/StreamRewarder.sol";
import {Vault} from "../src/Vault.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SalaryReceiptToken} from "../src/MockContracts/SalaryReceiptToken.sol"; 
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract deployVault is Script {


    address deployer = 0x03F391AeB0Ef8cAbEF46C075F66980E2e8FEB7b0;
    function run() public {

        vm.startBroadcast();

        SalaryReceiptToken salaryReceipt = new SalaryReceiptToken("Demoralizers Corp Receipt","DCR");

        StreamRewarder rewarder =  new StreamRewarder(deployer, 365 days);        

        vm.stopBroadcast();
    }
}

