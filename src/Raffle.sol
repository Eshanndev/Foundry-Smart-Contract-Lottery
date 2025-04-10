//SPDX-License-Identifier:MIT
pragma solidity^0.8.19;

/*///////////////////////////////////////////////
                  Imports
////////////////////////////////////////////////*/

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";


/**
 * @title A sample raffle contract
 * @author Induwara bandara
 * @notice This contract is for creating sample raffle
 * @dev implements chainlink VRFv2.5
 */
contract Raffle is VRFConsumerBaseV2Plus {

  /*///////////////////////////////////////////////
                  Enums
  ////////////////////////////////////////////////*/

  enum RaffleState {
  OPEN,
  COUNTING
  }

  /*///////////////////////////////////////////////
                  Errors
  ////////////////////////////////////////////////*/

  error Raffle__SendMoreToEnterRaffle();
  error Raffle__transferError();
  error Raffle__resultsCounting();
  error Raffle__upkeepNotNeeded(uint256 playersLength , uint256 contractBalance , RaffleState s_raffleState);

  /*///////////////////////////////////////////////
                  Events
  ////////////////////////////////////////////////*/

  event raffleEntered(address indexed player);
  event winnerPicked(address indexed winner);
  event requestedRaffleWinner(uint256 indexed requestId);


  /*///////////////////////////////////////////////
                  State Variables
  ////////////////////////////////////////////////*/

  uint16 private constant  REQUEST_CONFIRMATIONS =3 ;
  uint32 private constant NUM_WORDS = 1;

  uint256 private immutable i_entranceFee;
  uint256 private immutable i_interval;
  bytes32 private immutable i_keyHash;
  uint256 private immutable i_subId;
  uint32 private immutable i_callbackGasLimit;

  address payable[] private s_players;
  uint256 private s_lastTimeStamp;
  address payable private s_recentWinner;
  RaffleState private s_raffleState;
  

  

  /*///////////////////////////////////////////////
                  constructor
  ////////////////////////////////////////////////*/

  constructor(uint256 entranceFee,uint256 interval,address vrfCoordinator,bytes32 keyHash, uint256 subId, uint32 callbackGasLimit) VRFConsumerBaseV2Plus(vrfCoordinator){
    
    i_entranceFee = entranceFee;
    i_interval = interval;
    i_keyHash = keyHash;
    i_subId = subId;
    i_callbackGasLimit = callbackGasLimit;
    s_lastTimeStamp = block.timestamp;
    s_raffleState = RaffleState.OPEN;
    

  }

  /*///////////////////////////////////////////////
                  functions
  ////////////////////////////////////////////////*/

  function checkUpkeep(bytes memory) public view returns(bool upkeepNeeded, bytes memory){
    /**
     * 1.is interval passed
     * 2.is players entered atleaset an one
     * 3.do the contract have eth from players entrance fees
     * 4.is rafflestate open
     */

    bool isIntervalPassed = block.timestamp - s_lastTimeStamp > i_interval;
    bool isPlayersEntered = s_players.length > 0;
    bool isContractHasEth = address(this).balance > 0;
    bool isRaffleStateOpen = s_raffleState == RaffleState.OPEN;
    upkeepNeeded = isIntervalPassed && isPlayersEntered && isContractHasEth && isRaffleStateOpen;
    return (upkeepNeeded,"");
  }
  


  function enterRaffle()external payable{
    if (s_raffleState != RaffleState.OPEN){
      revert Raffle__resultsCounting();
    }
    if(msg.value < i_entranceFee){
      revert Raffle__SendMoreToEnterRaffle();
    }
    emit raffleEntered(msg.sender);
    s_players.push (payable(msg.sender));
  }


  function performUpkeep(bytes memory)public {
    (bool upkeepNeeded, ) = checkUpkeep("");
    if (!upkeepNeeded){
      revert Raffle__upkeepNotNeeded(s_players.length , address(this).balance, s_raffleState);
    }
    s_raffleState = RaffleState.COUNTING;

    VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest({
      keyHash: i_keyHash,
      subId:i_subId,
      requestConfirmations:REQUEST_CONFIRMATIONS,
      callbackGasLimit:i_callbackGasLimit,
      numWords:NUM_WORDS,
      extraArgs:VRFV2PlusClient._argsToBytes(
        VRFV2PlusClient.ExtraArgsV1({nativePayment:false})
      )
    });

    uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
    emit requestedRaffleWinner(requestId);
    

   
  }

  function fulfillRandomWords(uint256 /*requestId*/, uint256[] calldata randomWords) internal virtual override{
    uint256 recentWinnerIndex = randomWords[0] % s_players.length;
    s_recentWinner =  s_players[recentWinnerIndex];
    emit winnerPicked(s_recentWinner);
    s_players = new address payable[](0);
    s_raffleState = RaffleState.OPEN;
    (bool success, ) = s_recentWinner.call{value:address(this).balance}("");
    if (!success){
      revert Raffle__transferError();
    }
  }



  
  /*///////////////////////////////////////////////
                  getter functions
  ////////////////////////////////////////////////*/

  function getEntranceFee() public view returns(uint256){
    return i_entranceFee;
  }

  function getPlayer(uint256 index)public view returns(address){
    return s_players[index];
  }

  function getRaffleState()public view returns(RaffleState){
    return s_raffleState;
  } 

  function getInterval()public view returns(uint256){
    return i_interval;
  }

  function getRecentWinner()public view returns(address){
    return s_recentWinner;
  }
}