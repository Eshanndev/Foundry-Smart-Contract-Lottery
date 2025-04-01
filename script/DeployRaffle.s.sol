//SPDX-License-Identifier:MIT
pragma solidity ^0.8.26;

import {Raffle} from "../src/Raffle.sol";
import {Script} from "forge-std/Script.sol";

contract DeployRaffle is Script {

  uint256 entranceFee = 0.01 ether;
  uint256 interval = 3600;
  address vrfCoordinator = 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B;//can be changed
  bytes32 keyHash = 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae; 
  uint256 subId = 628368851340348519913626481334836042622242987999739258721281183736411821644;
  uint32 callbackGasLimit = 300000;

  function run() external returns(Raffle){
    vm.startBroadcast();
    Raffle raffle = new Raffle(
      entranceFee,
      interval,
      vrfCoordinator,
      keyHash,
      subId,
      callbackGasLimit
    );
    vm.stopBroadcast();
    return raffle;
  }

}