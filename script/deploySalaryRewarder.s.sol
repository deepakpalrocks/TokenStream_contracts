// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {StreamRewarder} from "../src/StreamRewarder.sol";
import {SalaryReceiptToken} from "../src/MockContracts/SalaryReceiptToken.sol"; 
import { USDT } from "../src/MockContracts/USDT.sol";

contract deployVault is Script {


    address deployer = 0x03F391AeB0Ef8cAbEF46C075F66980E2e8FEB7b0;
    function run() public {

        address employee1 = 0xf43FdA43F6F86A2b0b5b68BcbaAF39b21EBf732E;
        address employee2 = 0x1e2Ff11FF2CC0ee711dE41A492C9D193f8b2c897;
        address employee3 = 0x609F7D3a9767521CD8DDA6349464fC6FD96E7213;

        address employer = 0x03F391AeB0Ef8cAbEF46C075F66980E2e8FEB7b0;

        // vm.startBroadcast();
        vm.startPrank(employer);

        StreamRewarder rewarder =  new StreamRewarder(deployer, 365 days);        
        SalaryReceiptToken salaryReceipt = new SalaryReceiptToken("Deepak's Sample Receipt","DSR", address(rewarder));

        rewarder.setReceiptToken(address(salaryReceipt));
        rewarder.updateRewardQueuer(employer, true);
        salaryReceipt.whitelistForTransfer(employer, true);

        

        USDT usdt = new USDT("USDT", "USDT");

        salaryReceipt.mint(employer, 1000 ether);
        usdt.mint(employer, 1000000 ether);

        vm.startPrank(employer);
        salaryReceipt.transfer(employee1, 300 ether);
        salaryReceipt.transfer(employee2, 300 ether);
        salaryReceipt.transfer(employee3, 400 ether);

        usdt.approve(address(rewarder), 1000000 ether);
        rewarder.queueNewRewards(1000000 ether, address(usdt));

        vm.warp(block.timestamp + 5 days);

        uint256 earned1 = rewarder.earned(employee1, address(usdt));
        uint256 earned2 = rewarder.earned(employee2, address(usdt));
        uint256 earned3 = rewarder.earned(employee3, address(usdt));

        console.log("earned 1", earned1);
        console.log("earned 2", earned2);
        console.log("earned 3", earned3);

        vm.startPrank(employee1);
        rewarder.getReward(employee1);

        vm.startPrank(employee2);
        rewarder.getReward(employee2);

        vm.startPrank(employee3);
        rewarder.getReward(employee3);

        console.log("employee1 reward token balance: ", usdt.balanceOf(employee1));
        console.log("employee2 reward token balance: ", usdt.balanceOf(employee2));
        console.log("employee3 reward token balance: ", usdt.balanceOf(employee3));

        // vm.stopBroadcast();
    }
}

