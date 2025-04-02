//SPDX-License-Identifier:MIT
pragma solidity ^0.8.19;

import {Raffle} from "../src/Raffle.sol";
import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployRaffle is Script {


  function run() external returns(Raffle,HelperConfig){
    return deploy();
  }

  function deploy()public returns(Raffle,HelperConfig){


    HelperConfig helperConfig = new HelperConfig();

    
    HelperConfig.networkConfig memory config = helperConfig.getActiveNetworkConfig();
    

    vm.startBroadcast();
    Raffle raffle = new Raffle(
      config.entranceFee,
      config.interval,
      config.vrfCoordinator,
      config.keyHash,
      config.subId,
      config.callbackGasLimit
    );
    vm.stopBroadcast();
    return (raffle, helperConfig);

  }

}