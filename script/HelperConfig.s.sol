//SPDX-License-Identifier:MIT
pragma solidity ^0.8.19;



import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";




abstract contract CodeConstants {

  uint256 constant public SEPOLIA_CHAIN_ID =  11155111;
  uint256 constant public ANVIL_CHAIN_ID =  31337;
  uint96 constant public MOCK_BASE_FEE = 0.25 ether;
  uint96 constant public MOCK_GAS_PRICE = 1e9;
  int256 constant public MOCK_WEI_PER_UNIT_LINK = 4e15 ;

}





contract HelperConfig is CodeConstants,Script {

  
  error HelperConfig__invalidNetwork();
  error HelperConfig__invalidChainId(uint256 chainid);

  struct networkConfig{
    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 keyHash;
    uint256 subId;
    uint32 callbackGasLimit;
    address link;
    
  }

  networkConfig private anvilEthConfig;
  
  mapping(uint256 chainid => networkConfig) public networkConfigs;

 /**@dev mapping chain id s to network configs */
  constructor(){
    networkConfigs[SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();
  }


/**@notice when we call getConfig() it returns current active network configs */
  function getConfig () public returns(networkConfig memory){
    return getConfigByChainid(block.chainid);
  }

  function getConfigByChainid(uint256 _chainid) public returns(networkConfig memory){
    if(networkConfigs[_chainid].vrfCoordinator != address(0)){ // we can use any field of the struct to checl this condition
      return networkConfigs[_chainid];
    }else if(_chainid == ANVIL_CHAIN_ID){
      return getOrCreateAnvilEthConfig();
    }else {
      revert HelperConfig__invalidChainId(_chainid);
    }
  }

  
  /**@notice this allows dev to add more supported network easily wthout changing source code 
   * @dev mapping chain id s to network configs that want to add more
  */
  function setConfig(uint256 _chainid , networkConfig memory _networkConfig)public {
    networkConfigs[_chainid] = _networkConfig;
  }


  /**@notice return sepolia networkConfig */
  function getSepoliaEthConfig()public pure returns(networkConfig memory){
    networkConfig memory sepoliaEthConfig = networkConfig({
        entranceFee:0.01 ether,
        interval:30,
        keyHash:0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,subId:628368851340348519913626481334836042622242987999739258721281183736411821644,
        vrfCoordinator:0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
        callbackGasLimit:500000,
        link:0x779877A7B0D9E8603169DdbD7836e478b4624789 //0x779877A7B0D9E8603169DdbD7836e478b4624789
      });
    return sepoliaEthConfig;
  }

  /**@notice  we use a mock vrfcordinator contract in anvil. because of using the contract address by default we have to deply the mock contract to anvil and get the contract address
   * @dev there is no need of deploying it again and again if a previous contract exists.
   * so first check if vrfcoordinator in anvil network config is empty or not. only if its empty create an one
   * 
  */
  function getOrCreateAnvilEthConfig()public returns(networkConfig memory){
    if (anvilEthConfig.vrfCoordinator != address(0)){
      return anvilEthConfig;
    }else {
      
      
      vm.startBroadcast();
      VRFCoordinatorV2_5Mock mockVRFCoordinator = new VRFCoordinatorV2_5Mock(
        MOCK_BASE_FEE,
        MOCK_GAS_PRICE,
        MOCK_WEI_PER_UNIT_LINK
      );
      vm.stopBroadcast();

      anvilEthConfig = networkConfig({
        entranceFee:0.01 ether,
        interval:30,
        keyHash:0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
        subId:0,
        vrfCoordinator:address(mockVRFCoordinator),
        callbackGasLimit:500000,
        link:address(0)   //we gonna deploy link contract in anvil and add to here , for now lets just make it 0X00...
      });
    return anvilEthConfig;


    }
  }

  //getter function 

 

  
}