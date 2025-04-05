//SPDX-License-Identifier:MIT
pragma solidity ^0.8.19;

import {Test,console} from "forge-std/Test.sol";
//import {console} from "forge-std/console.sol";
import {Raffle} from "../../src/Raffle.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract TestRaffle is Test{

  /**events */
  event raffleEntered(address indexed player);
  event winnerPicked(address indexed winner);


  DeployRaffle deployRaffle = new DeployRaffle();
  Raffle raffle;
  HelperConfig helperConfig;
  address USER = makeAddr("user");
  address USER2 = makeAddr("user2");
  uint256 USER_STARTING_BALANCE = 10 ether;
  uint256 SENDING_ETH_AMOUNT = 0.1 ether;


  function setUp()public {
    (raffle,) = deployRaffle.run();
    
    vm.deal(USER, USER_STARTING_BALANCE);
    vm.deal(USER2, USER_STARTING_BALANCE);
  }



  function testRaffle_playersShouldPayEntranceFee()public {
    vm.prank(USER);
    vm.expectRevert(Raffle.Raffle__SendMoreToEnterRaffle.selector);
    raffle.enterRaffle();
  }

  function testRaffle_playersCanEnter() public {
    uint256 startingContractBalance = address(raffle).balance;
    

    vm.prank(USER);
    raffle.enterRaffle{value:SENDING_ETH_AMOUNT}();

    uint256 endingContractBalance = address(raffle).balance;
    

    assertEq(endingContractBalance, startingContractBalance + SENDING_ETH_AMOUNT);
    assertEq(address(USER).balance , USER_STARTING_BALANCE - SENDING_ETH_AMOUNT);
  }

  function testRaffle_enteredPlayersRecord() public {
    vm.prank(USER);
    raffle.enterRaffle{value:SENDING_ETH_AMOUNT}();

    address player = raffle.getPlayer(0);
    assertEq(USER, player);
  }


  function testRaffle_raffleStateIsInitializedToOpen() public view{
    assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
  }

  function testRaffle_raffleEnteredEventEmiting() public {
    vm.prank(USER);

    vm.expectEmit(true, false, false, false, address(raffle));
    emit raffleEntered(USER);

    raffle.enterRaffle{value:SENDING_ETH_AMOUNT}();
  }

  function testRaffle_notAllowingPlayersEnterWhileCounting()public {
    vm.prank(USER);
    raffle.enterRaffle{value:SENDING_ETH_AMOUNT}();
    vm.prank(USER2);
    raffle.enterRaffle{value:SENDING_ETH_AMOUNT}();

    vm.warp(block.timestamp + raffle.getInterval() + 1);
    vm.roll(block.number + 1);
    raffle.performUpkeep("");

    //now raffle state has been set to COUNTING
    //so now try to enter raffle
    vm.prank(USER);
    vm.expectRevert(Raffle.Raffle__resultsCounting.selector);
    raffle.enterRaffle{value:SENDING_ETH_AMOUNT}();

  }

}