//SPDX-License-Identifier:MIT
pragma solidity ^0.8.19;



import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

error HelperConfig__invalidNetwork();


abstract contract codeConstants {

  uint256 constant public SEPOLIA_CHAIN_ID =  11155111;
  uint256 constant public ANVIL_CHAIN_ID =  31337;
  uint96 constant public MOCK_BASE_FEE = 0.25 ether;
  uint96 constant public MOCK_GAS_PRICE = 1e9;
  int256 constant public MOCK_WEI_PER_UNIT_LINK = 4e15 ;

}





contract HelperConfig is codeConstants,Script {

  
  

  struct networkConfig{
    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 keyHash;
    uint256 subId;
    uint32 callbackGasLimit;
    
  }

  networkConfig private activeNetworkConfig;
  

  constructor(){
    if(block.chainid == SEPOLIA_CHAIN_ID){
      activeNetworkConfig = getSepoliaEthConfig();
    }else if(block.chainid == ANVIL_CHAIN_ID){
      activeNetworkConfig = getOrCreateAnvilEthConfig();
    }else{
      revert HelperConfig__invalidNetwork();
    }
  }

  

  function getSepoliaEthConfig()public pure returns(networkConfig memory){
    networkConfig memory sepoliaEthConfig = networkConfig({
        entranceFee:0.01 ether,
        interval:3600,
        keyHash:0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,subId:628368851340348519913626481334836042622242987999739258721281183736411821644,
        vrfCoordinator:0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
        callbackGasLimit:500000
      });
    return sepoliaEthConfig;
  }

  function getOrCreateAnvilEthConfig()public returns(networkConfig memory){
    if (activeNetworkConfig.vrfCoordinator != address(0)){
      return activeNetworkConfig;
    }else {
      
      //deploy the mock vrf coordinator and get the CA
      vm.startBroadcast();
      VRFCoordinatorV2_5Mock mockVRFCoordinator = new VRFCoordinatorV2_5Mock(
        MOCK_BASE_FEE,
        MOCK_GAS_PRICE,
        MOCK_WEI_PER_UNIT_LINK
      );
      vm.stopBroadcast();

      networkConfig memory anvilEthConfig = networkConfig({
        entranceFee:0.01 ether,
        interval:3600,
        keyHash:0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,subId:628368851340348519913626481334836042622242987999739258721281183736411821644,
        vrfCoordinator:address(mockVRFCoordinator),
        callbackGasLimit:500000
      });
    return anvilEthConfig;


    }
  }

  //getter function 

  function getActiveNetworkConfig() public view returns(networkConfig memory){
    return activeNetworkConfig;
  }

  
}