// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/raffle/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {console} from "forge-std/Test.sol";
import {SubscriptionCreater, ConsumerAdder, SubscriptionFunder} from "./Interactions.s.sol";

contract RaffleDeployer is Script {
    function run() public {
        deployContract();
    }

    function deployContract() public returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory networkConfig = helperConfig.getCurrentNetworkConfig();

        //To fund Sepolia or Mainnet subscription I will have to directly run the script

        if (networkConfig.subscriptionId == 0) {
            // In case the env is local
            // create subscription
            SubscriptionCreater subscriptionCreater = new SubscriptionCreater();
            (networkConfig.subscriptionId, networkConfig.vrfCoordinator) =
                subscriptionCreater.createSubscription(networkConfig.vrfCoordinator, networkConfig.account);

            // fund subscription
            SubscriptionFunder subscriptionFunder = new SubscriptionFunder();
            subscriptionFunder.fundSubscription(
                networkConfig.vrfCoordinator, networkConfig.subscriptionId, networkConfig.link, networkConfig.account
            );
        }
        vm.startBroadcast(networkConfig.account);
        Raffle raffle = new Raffle(
            networkConfig.ticketPrice,
            networkConfig.intervalInSeconds,
            networkConfig.vrfCoordinator,
            networkConfig.gasLane,
            networkConfig.subscriptionId,
            networkConfig.callbackGasLimit
        );
        vm.stopBroadcast();

        //add consumer
        ConsumerAdder consumerAdder = new ConsumerAdder();
        consumerAdder.addConsumer(
            address(raffle), networkConfig.vrfCoordinator, networkConfig.subscriptionId, networkConfig.account
        );

        return (raffle, helperConfig);
    }
}
