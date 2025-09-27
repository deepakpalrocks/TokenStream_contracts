// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {StreamRewarder} from "../src/StreamRewarder.sol";
import {Vault} from "../src/Vault.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {MintableERC20} from "../src/MockContracts/MintableERC20.sol"; 
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract deployVault is Script {

    address public deployer = 0x9CB6F161cBf0d17BB97BC30eBF077d6c0C20E945;

    address public randomUser = makeAddr("randomUser");
    address public randomUser2 = makeAddr("randomUser2");

    function setUp() public {}

    function run() public {

        // vm.startBroadcast();
        vm.startPrank(deployer);

        // Deploy mock tokens for deposit and reward
        MintableERC20 depositToken = new MintableERC20("USDT", "USDT");
        MintableERC20 rewardToken = new MintableERC20("WBTC", "WBTC");

        // Deploy streamRewarder
        ProxyAdmin proxyAdmin = new ProxyAdmin(deployer); // This is used only when we can to upgrade a contract
        StreamRewarder streamRewarderImpl = new StreamRewarder();
        TransparentUpgradeableProxy streamRewarderProxy = new TransparentUpgradeableProxy(address(streamRewarderImpl), address(proxyAdmin), "");
        StreamRewarder streamRewarder = StreamRewarder(address(streamRewarderProxy));
        streamRewarder.initialize(deployer, 100 days); // This is how we initialize proxy contracts instead of constructor

        // Deploy vault
        Vault tokenVault = new Vault(IERC20(address(depositToken)), "USDT Vault", "Vault-USDT", address(streamRewarder));

        // Vault is also the receipt token
        streamRewarder.setReceiptToken(address(tokenVault));


        // ========================================== User Simulations ==========================================

        // Mint deposit token to deployer
        depositToken.mint(randomUser2, 100 ether); // in real world we dont mint, we need to buy it from a dex
        depositToken.mint(randomUser, 50 ether); // in real world we dont mint, we need to buy it from a dex

        // random user 2 deposits 100 USDT into the vault
        vm.startPrank(randomUser2);
        depositToken.approve(address(tokenVault), 100 ether);
        tokenVault.deposit(100 ether, randomUser2); // deployer will deposit 100 USDT and receive 100 shares(vault tokens)
        console.log("randomUser2 vault balance after Deposit: ", tokenVault.balanceOf(randomUser2));

        // Random user deposits 100 USDT into the vault
        vm.startPrank(randomUser);
        depositToken.approve(address(tokenVault), 50 ether);
        tokenVault.deposit(50 ether, randomUser); // randomUser will deposit 100 USDT and receive 100 shares(vault tokens)
        console.log("Random user vault balance after Deposit: ", tokenVault.balanceOf(randomUser));

        // deployer will send reward tokens to stream rewarder which will distribute them to the vault holders over a period of 100 days
        vm.startPrank(deployer);
        rewardToken.mint(address(deployer), 1000 ether); // in real world we dont mint, we need to buy it from a dex
        rewardToken.approve(address(streamRewarder), 1000 ether);
        streamRewarder.queueNewRewards(1000 ether, address(rewardToken));

        // Move forward in time by 10 days
        vm.warp(block.timestamp + 10 days);

        // Notice how random user earned half the rewards than deployer cuz he deposited half the amount
        uint256 randomUserEarnedRewards2 = streamRewarder.earned(randomUser2, address(rewardToken)); // will show claimmable rewards amount
        console.log("randomUser2 earned rewards: ", randomUserEarnedRewards2);
        uint256 randomUserEarnedRewards = streamRewarder.earned(randomUser, address(rewardToken));
        console.log("Random user earned rewards: ", randomUserEarnedRewards);

        // claim the rewards
        streamRewarder.getReward(randomUser2);
        streamRewarder.getReward(randomUser);

        // Check the reward token balances of the 2 users of the vault
        console.log("randomUser2 reward token balance: ", rewardToken.balanceOf(randomUser2));
        console.log("Random user reward token balance: ", rewardToken.balanceOf(randomUser));
        // Notice how 1000 reward tokens were sent for 100 days so after 10 days 100 reward tokens were distributed total to both users
        // This is what the stream rewarder does, it distributes the rewards to the vault holders over a period of time linearly
        // And the distribution happens on the basis of the total amount of vault tokens held by the user

        // Now we can withdraw the deposit token from the vault
        vm.startPrank(randomUser2);
        tokenVault.withdraw(60 ether, randomUser2, randomUser2);
        console.log("randomUser2 vault balance after Withdraw: ", tokenVault.balanceOf(randomUser2));
        console.log("randomUser2 deposit token balance after Withdraw: ", depositToken.balanceOf(randomUser2));

        vm.stopPrank();
        // vm.stopBroadcast();
    }
}
