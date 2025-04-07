//SPDX-License-Identifier:MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {HelperConfig, CodeConstants} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script{

  function run()public {
    createSubscriptionUsingConfig();
  }

  function createSubscriptionUsingConfig() public returns(uint256, address){
    HelperConfig helperConfig = new HelperConfig();
    address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
    (uint256 subId,) = createSubscription(vrfCoordinator);
    return(subId,vrfCoordinator);
  }

  function createSubscription(address _vrfCoordinator) public returns(uint256, address){
    vm.startBroadcast();
    uint256 subId = VRFCoordinatorV2_5Mock(_vrfCoordinator).createSubscription();
    vm.stopBroadcast();
    return(subId,_vrfCoordinator);
  }

}

contract FundSubscription is CodeConstants, Script{

  uint256 constant public FUND_AMOUNT = 1 ether;// or 3 Link


  function run()public {
    fundSubscriptionUsingConfig();
  }

  function fundSubscriptionUsingConfig() public {
    HelperConfig helperConfig = new HelperConfig();

    address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
    uint256 subId = helperConfig.getConfig().subId;
    address link = helperConfig.getConfig().link;

    fundSubscription(vrfCoordinator, subId, link);
  }

  function fundSubscription(address _vrfCoordinator, uint256 _subId, address _link) public {
    if (block.chainid == ANVIL_CHAIN_ID){
      vm.startBroadcast();
      VRFCoordinatorV2_5Mock(_vrfCoordinator).fundSubscription(_subId,FUND_AMOUNT);
      vm.stopBroadcast();
    }else {
      vm.startBroadcast();
      LinkToken(_link).transferAndCall(_vrfCoordinator,FUND_AMOUNT,abi.encode(_subId));
      vm.stopBroadcast();
    }
  }

  
}

contract AddConsumer is Script {

  function run() public {
    address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("Raffle",block.chainid);
    addConsumerUsingConfig(mostRecentlyDeployed);
  }

  function addConsumerUsingConfig(address mostRecentlyDeployed)public {
    HelperConfig helperConfig = new HelperConfig();
    uint256 subId = helperConfig.getConfig().subId;
    address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;

    addConsumer(vrfCoordinator,subId,mostRecentlyDeployed );
  }

  function addConsumer(address vrfCoordinator, uint256 subId, address mostRecentlyDeployed)public {
    vm.startBroadcast();
    VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subId,mostRecentlyDeployed);
    vm.stopBroadcast();
  }

}
