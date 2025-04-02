//SPDX-License-Identifier:MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {Raffle} from "../src/Raffle.sol";
import {DeployRaffle} from "../script/DeployRaffle.s.sol";

contract TestRaffle is Test{

  DeployRaffle deployRaffle = new DeployRaffle();
  Raffle raffle;
  address USER = makeAddr("user");
  uint256 USER_STARTING_BALANCE = 10 ether;
  uint256 SENDING_ETH_AMOUNT = 0.1 ether;

  function setUp()public {
    (raffle,) = deployRaffle.run();
    
    vm.deal(USER, USER_STARTING_BALANCE);
  }

  function testRaffle_playersShouldPayEntranceFee()public {
    vm.prank(USER);
    vm.expectRevert();
    raffle.enterRaffle();
  }

  function testRaffle_playersCanEnter() public {
    uint256 startingContractBalance = address(raffle).balance;
    uint256 startingUserBlance = USER_STARTING_BALANCE;

    vm.prank(USER);
    raffle.enterRaffle{value:SENDING_ETH_AMOUNT}();

    uint256 endingContractBalance = address(raffle).balance;
    

    assertEq(endingContractBalance, startingContractBalance + SENDING_ETH_AMOUNT);
    assertEq(address(USER).balance , USER_STARTING_BALANCE - SENDING_ETH_AMOUNT);
  }

  

}