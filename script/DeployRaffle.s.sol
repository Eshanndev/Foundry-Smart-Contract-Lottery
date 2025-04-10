//SPDX-License-Identifier:MIT
pragma solidity ^0.8.19;

import {Raffle} from "../src/Raffle.sol";
import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription,FundSubscription,AddConsumer} from "./interactions.s.sol";


contract DeployRaffle is Script {


  function run() external returns(Raffle,HelperConfig){
    return deploy();
  }

  function deploy()public returns(Raffle,HelperConfig){


    HelperConfig helperConfig = new HelperConfig();
    

    
    HelperConfig.networkConfig memory config = helperConfig.getConfig();

    if(config.subId == 0){
      CreateSubscription createSubscription = new CreateSubscription();
      (config.subId, config.vrfCoordinator) = createSubscription.createSubscription(config.vrfCoordinator , config.account);
    }

    FundSubscription fundSubscription = new FundSubscription();
    fundSubscription.fundSubscription(config.vrfCoordinator, config.subId, config.link, config.account);

    

    vm.startBroadcast(config.account);
    Raffle raffle = new Raffle(
      config.entranceFee,
      config.interval,
      config.vrfCoordinator,
      config.keyHash,
      config.subId,
      config.callbackGasLimit
    );
    vm.stopBroadcast();

    AddConsumer addConsumer = new AddConsumer();
    addConsumer.addConsumer(config.vrfCoordinator ,config.subId, address(raffle), config.account);

    return (raffle, helperConfig);

  }

}