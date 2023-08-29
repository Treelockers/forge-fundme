// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundme;
    address USER = makeAddr("user");
    uint constant SEND_VALUE = 0.1 ether;
    uint constant STARTING_BALANCE = 10 ether;
    uint constant GAS_PRICE = 1;

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundme = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMINIMUM_USD() public {
        assertEq(fundme.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public {
        assertEq(fundme.getOwner(), msg.sender);
    }

    function testPriceFeedVersion() public {
        assertEq(fundme.getVersion(), 4);
    }

    function testFundWithoutEnoughETh() public {
        vm.expectRevert();
        fundme.fund();
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER);
        fundme.fund{value: SEND_VALUE}();
        uint amountFunded = fundme.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER);
        fundme.fund{value: SEND_VALUE}();
        address funder = fundme.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundme.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.prank(USER);
        vm.expectRevert();
        fundme.withdraw();
    }

    function testWithdrawASingleFunder() public funded {
        uint startingOwnerBalance = fundme.getOwner().balance;
        uint startingFundMeBalance = address(fundme).balance;

        uint gasStart = gasleft();

        vm.txGasPrice(GAS_PRICE);
        vm.prank(fundme.getOwner());
        fundme.withdraw();

        uint gasEnd = gasleft();
        uint gasUsed = (gasStart - gasEnd) * tx.gasprice;

        console.log(gasUsed);

        uint endingOwnerBalance = fundme.getOwner().balance;
        uint endingFundMeBalance = address(fundme).balance;

        assertEq(endingFundMeBalance, 0);
        assertEq(
            endingOwnerBalance,
            startingOwnerBalance + startingFundMeBalance
        );
    }

    function testWithdrawMultipleFunders() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE);
            fundme.fund{value: SEND_VALUE}();
        }

        uint startingOwnerBalance = fundme.getOwner().balance;
        uint startingFundMeBalance = address(fundme).balance;

        vm.startPrank(fundme.getOwner());
        fundme.withdraw();
        vm.stopPrank();

        uint endingOwnerBalance = fundme.getOwner().balance;
        uint endingFundMeBalance = address(fundme).balance;

        assertEq(endingFundMeBalance, 0);
        assertEq(
            endingOwnerBalance,
            startingOwnerBalance + startingFundMeBalance
        );
    }

    function testWithdrawMultipleFundersCheaper() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE);
            fundme.fund{value: SEND_VALUE}();
        }

        uint startingOwnerBalance = fundme.getOwner().balance;
        uint startingFundMeBalance = address(fundme).balance;

        vm.startPrank(fundme.getOwner());
        fundme.cheaperWithdraw();
        vm.stopPrank();

        uint endingOwnerBalance = fundme.getOwner().balance;
        uint endingFundMeBalance = address(fundme).balance;

        assertEq(endingFundMeBalance, 0);
        assertEq(
            endingOwnerBalance,
            startingOwnerBalance + startingFundMeBalance
        );
    }
}
