//SPDX-License-Identifier:MIT
pragma solidity ^0.8.19;


/*///////////////////////////////////////////////
                  Imports
////////////////////////////////////////////////*/

import {Test,console} from "forge-std/Test.sol";
//import {console} from "forge-std/console.sol";
import {Raffle} from "../../src/Raffle.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig,CodeConstants} from "../../script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract TestRaffle is Test, CodeConstants{

  /*///////////////////////////////////////////////
                  Errors
  ////////////////////////////////////////////////*/

  error Raffle__SendMoreToEnterRaffle();
  error Raffle__transferError();
  error Raffle__resultsCounting();
  error Raffle__upkeepNotNeeded(uint256 playersLength , uint256 contractBalance , RaffleState s_raffleState);

  

  /*///////////////////////////////////////////////
                  Enums
  ////////////////////////////////////////////////*/

  enum RaffleState {
    OPEN,
    COUNTING
  }

  /*///////////////////////////////////////////////
                  Events
  ////////////////////////////////////////////////*/

  event raffleEntered(address indexed player);
  event winnerPicked(address indexed winner);

  /*///////////////////////////////////////////////
                Instances & State Variables
  ////////////////////////////////////////////////*/

  DeployRaffle deployRaffle = new DeployRaffle();
  Raffle raffle;
  HelperConfig helperConfig;
  address USER = makeAddr("user");
  
  uint256 USER_STARTING_BALANCE = 10 ether;
  uint256 SENDING_ETH_AMOUNT = 0.1 ether;

  /*///////////////////////////////////////////////
                  Setup Function
  ////////////////////////////////////////////////*/

  function setUp()public {
    (raffle,helperConfig) = deployRaffle.run();

    
    vm.deal(USER, USER_STARTING_BALANCE);
    
  }

  /*///////////////////////////////////////////////
                  Modifiers
  ////////////////////////////////////////////////*/

  modifier usersEnteredAndIntervalPassed(){
    vm.prank(USER);
    raffle.enterRaffle{value:SENDING_ETH_AMOUNT}();
    

    vm.warp(block.timestamp + raffle.getInterval() + 1);
    vm.roll(block.number + 1);
    _;
  }

  modifier skipOnForkTest(){
    if (block.chainid == SEPOLIA_CHAIN_ID){
      return;
    }
    _;
  }

  

  /*///////////////////////////////////////////////
              enterRaffle Tests
  ////////////////////////////////////////////////*/


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

  function testRaffle_raffleEnteredEventEmiting() public {
    vm.prank(USER);

    vm.expectEmit(true, false, false, false, address(raffle));
    emit raffleEntered(USER);

    raffle.enterRaffle{value:SENDING_ETH_AMOUNT}();
  }

  function testRaffle_notAllowingPlayersEnterWhileCounting()public usersEnteredAndIntervalPassed{
    
    raffle.performUpkeep("");

    //now raffle state has been set to COUNTING
    //so now try to enter raffle
    vm.prank(USER);
    vm.expectRevert(Raffle.Raffle__resultsCounting.selector);
    raffle.enterRaffle{value:SENDING_ETH_AMOUNT}();

  }

  /*///////////////////////////////////////////////
           Enums & Variables Tests
  ////////////////////////////////////////////////*/

  function testRaffle_enteredPlayersRecord() public {
    vm.prank(USER);
    raffle.enterRaffle{value:SENDING_ETH_AMOUNT}();

    address player = raffle.getPlayer(0);
    assertEq(USER, player);
  }


  function testRaffle_raffleStateIsInitializedToOpen() public view{
    assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
  }

  
  /*///////////////////////////////////////////////
              checkUpKeep Tests
  ////////////////////////////////////////////////*/

  function testRaffle_checkUpKeepReturnFalseIfBalanceIsZero()public {
    vm.warp(block.timestamp + raffle.getInterval() + 1);
    vm.roll(block.number + 1);

    (bool upkeepNeeded, ) = raffle.checkUpkeep("");
    assert(!upkeepNeeded);
  }

  function testRaffle_checkUpKeepReturnFalseIfIntervalHasNotPassed()public{
    
    vm.prank(USER);
    raffle.enterRaffle{value:SENDING_ETH_AMOUNT}();
    

    (bool upkeepNeeded, ) = raffle.checkUpkeep("");
    assert(!upkeepNeeded);
  }

  function testRaffle_checkUpKeepReturnFalseIfRaffleStateIsCounting()public usersEnteredAndIntervalPassed{

    raffle.performUpkeep("");

    
    (bool upkeepNeeded, ) = raffle.checkUpkeep("");
    assert(!upkeepNeeded);

  }

  /*///////////////////////////////////////////////
              performUpKeep Tests
  ////////////////////////////////////////////////*/


  function testRaffle_perfromUpKeepOnlyRunIfUpKeepNeededIsTrue()public usersEnteredAndIntervalPassed{
    
    raffle.performUpkeep("");
  }

  function testRaffle_perfromUpKeepRevertIfUpKeeNeededIsFalse()public{
    uint256 playersLength = 1;
    uint256 contractBalance =SENDING_ETH_AMOUNT;
    Raffle.RaffleState raffleState = raffle.getRaffleState();

    vm.prank(USER);
    raffle.enterRaffle{value:SENDING_ETH_AMOUNT}();

    

    vm.expectRevert(abi.encodeWithSelector(Raffle.Raffle__upkeepNotNeeded.selector, playersLength, contractBalance, raffleState));

    raffle.performUpkeep("");

  }

  function testRaffle_performUpKeepChangesRaffleState()public usersEnteredAndIntervalPassed{
    
    Raffle.RaffleState preRaffleState = raffle.getRaffleState();
    raffle.performUpkeep("");
    Raffle.RaffleState postRaffleState = raffle.getRaffleState();

    assert(preRaffleState != postRaffleState);

    //now check if event is emiting correctly

  }

  function testRaffle_performUpKeepEmitingEventCorrectly()public usersEnteredAndIntervalPassed{
    

    vm.recordLogs();
    raffle.performUpkeep("");
    Vm.Log[] memory entries = vm.getRecordedLogs();
    bytes32 requestId = entries[1].topics[1];

    assert(requestId > 0);
  }

  /*///////////////////////////////////////////////
              fulfillRandomWords Tests
  ////////////////////////////////////////////////*/

  function testRaffle_fullfillRandomWordsOnlyCanBeCalledAfterPerformUpKeep(uint256 randomNumber)public usersEnteredAndIntervalPassed skipOnForkTest/*either way this is going to fail if test on a fork because of a evm error*/{
    //without calling performUpKeep try to call fullfillRandomWords

    
    address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;

    
     
    vm.expectRevert();
    VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(randomNumber, address(raffle));
    

  }

  function testRaffle_fullfillRandomWordsPicksAWinnerAndPayThem()public usersEnteredAndIntervalPassed skipOnForkTest{

    address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
    
    vm.recordLogs();
    raffle.performUpkeep("");
    Vm.Log[] memory entries = vm.getRecordedLogs();
    bytes32 requestId = entries[1].topics[1];

    VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(uint256(requestId),address(raffle));

    address recentWinner = raffle.getRecentWinner();
    assert(USER == recentWinner);

  }




  

  /*///////////////////////////////////////////////
              getterFunctions Tests
  ////////////////////////////////////////////////*/

  function testRaffle_getEntranceFeeIsWorking()public view{
    uint256 expectedEntranceFee = 0.01 ether;
    assert(expectedEntranceFee == raffle.getEntranceFee());
  }

  function testRaffle_getIntervalIsWorking()public view{
    uint256 expectedInterval = 30;
    assert(expectedInterval == raffle.getInterval());
  }


}