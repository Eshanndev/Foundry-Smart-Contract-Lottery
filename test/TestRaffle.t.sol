//SPDX-License-Identifier:MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {Raffle} from "../src/Raffle.sol";
import {DeployRaffle} from "../script/DeployRaffle.s.sol";

contract TestRaffle is Test{

  DeployRaffle deployRaffle = new DeployRaffle();
  Raffle raffle;
  // address constant USER;

  function setUp()public {
    raffle = deployRaffle.run();
  }

  

}