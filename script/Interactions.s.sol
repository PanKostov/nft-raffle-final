// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {Raffle} from "../src/raffle/Raffle.sol";
import {HelperConfig, HelperConstants} from "./HelperConfig.s.sol";
import {console} from "forge-std/Test.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

/* This class is used to create subscription locally (anvil chain)*/
contract SubscriptionCreater is Script {
    function createSubscriptionUsingConfig() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getCurrentNetworkConfig().vrfCoordinator;
        address account = helperConfig.getCurrentNetworkConfig().account;
        return createSubscription(vrfCoordinator, account);
    }

    function createSubscription(address vrfCoodrinator, address account) public returns (uint256, address) {
        console.log("Creating subscription on chain id : ", block.chainid);

        vm.startBroadcast(account);
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoodrinator).createSubscription();
        vm.stopBroadcast();

        console.log("Your subscription id is: ", subId);
        console.log("Please update the subscibtio id in your HelperConfig.s.sol");
        return (subId, vrfCoodrinator);
    }

    function run() public {
        createSubscriptionUsingConfig();
    }
}
/////////////////////////////////////////////////////////////////////////////////////

contract SubscriptionFunder is HelperConstants, Script {
    uint256 public constant FUND_AMOUNT = 3e18; //3 link

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getCurrentNetworkConfig().vrfCoordinator;
        uint256 subscriptionid = helperConfig.getCurrentNetworkConfig().subscriptionId;
        address linkToken = helperConfig.getCurrentNetworkConfig().link;
        address account = helperConfig.getCurrentNetworkConfig().account;
        fundSubscription(vrfCoordinator, subscriptionid, linkToken, account);
    }

    function run() public {
        fundSubscriptionUsingConfig();
    }

    function fundSubscription(address vrfCoordinator, uint256 subscriptionId, address linkToken, address account)
        public
    {
        console.log("Funding subscription: ", subscriptionId);
        console.log("Using vrfCoordinator", vrfCoordinator);
        console.log("On chainId ", block.chainid);

        if (block.chainid == LOCAL_CHAIN_ID) {
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subscriptionId, FUND_AMOUNT * 100);
            vm.stopBroadcast();
        } else {
            vm.startBroadcast(account);
            LinkToken(linkToken).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encode(subscriptionId));
            vm.stopBroadcast();
        }
    }
}

contract ConsumerAdder is Script {
    function addConsumer(address contractToAddToVrf, address vrfCoordinator, uint256 subId, address account) public {
        console.log("Adding consumer contract: ", contractToAddToVrf);
        console.log("Using vrfCoordinator: ", vrfCoordinator);
        console.log("On ChainID: ", block.chainid);
        vm.startBroadcast(account);
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subId, contractToAddToVrf);
        vm.stopBroadcast();
    }

    function addConsumerUsingConfig(address mostRecentlyDeployed) public {
        HelperConfig helperConfig = new HelperConfig();
        uint256 subId = helperConfig.getCurrentNetworkConfig().subscriptionId;
        address vrfCoordinator = helperConfig.getCurrentNetworkConfig().vrfCoordinator;
        address account = helperConfig.getCurrentNetworkConfig().account;

        addConsumer(mostRecentlyDeployed, vrfCoordinator, subId, account);
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        addConsumerUsingConfig(mostRecentlyDeployed);
    }
}
