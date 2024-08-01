// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

import {TicketNft} from "../nft/TicketNft.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 * @title A sample Raffle Contract
 * @author Panayot Kostov
 * @notice This contract is for creating a sample raffle
 * @dev Implements Chainlink VRFv2
 */
contract Raffle is VRFConsumerBaseV2Plus {
    error Raffle__NotEnoughEthSent();
    error Raffle__SellingTicketsIsClosed();
    error Raffle__RaffleIsClosed();
    error Raffle__TransferFailed();
    error Raffle__WinnerNotPickedYet();
    error Raffle__UpkeepNotNeeded(uint256 balance, uint256 currentDrawTicketsMinted, RaffleState raffleState);

    /* Type Declarations */
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    uint256 private immutable i_ticketPrice;
    uint256 private immutable i_intervalInSeconds;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    bytes32 private immutable i_gasLine;

    TicketNft private immutable i_ticketNft;
    address private immutable i_owner;

    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    uint256 private s_currentDrawTicketsMinted;
    RaffleState private s_raffleState;
    uint256 private s_ownerWithdrawAmount;

    /**
     * Events
     */
    event Raffle__EnteredRaffle(address indexed player);
    event Raffle__PickedWinner(address indexed winner);
    event Raffle__RequestRaffleWinner(uint256 indexed requestId);

    constructor(
        uint256 ticketPrice,
        uint256 intervalInSeconds,
        address vrfCoordinator,
        bytes32 gasLine,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_ticketPrice = ticketPrice;
        i_intervalInSeconds = intervalInSeconds;
        i_gasLine = gasLine;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;

        i_ticketNft = new TicketNft();
        i_owner = msg.sender;

        s_raffleState = RaffleState.OPEN;
        s_lastTimeStamp = block.timestamp;
    }

    function buyRaffleTicket() external payable {
        if (msg.value < i_ticketPrice) {
            revert Raffle__NotEnoughEthSent();
        }
        if (s_raffleState == RaffleState.CALCULATING) {
            revert Raffle__SellingTicketsIsClosed();
        }
        //Makes migration and front-end indexing easier
        emit Raffle__EnteredRaffle(msg.sender);

        i_ticketNft.mintnft(msg.sender);
        s_currentDrawTicketsMinted++;
    }

    /**
     * @dev This is the function that the Chainlink nodes will call to see
     * if the lottery is ready  to have a winner picked.
     * The following should be true in order for upkeepNeeded to be true:
     * 1. The time interval has passed between raffle runs
     * 2. The lottery is open
     * 3. The contract has ETH
     * 4. Implicitly, your subscription has LINK
     * @param - ignored
     * @return upkeepNeeded - true if it's time to restart the lottery
     * @return - ignored
     */
    function checkUpkeep(bytes memory /*checkData */ )
        public
        view
        returns (bool upkeepNeeded, bytes memory /*performData*/ )
    {
        bool timeHasPassed = block.timestamp - s_lastTimeStamp >= i_intervalInSeconds;
        bool isOpen = s_raffleState == RaffleState.OPEN;
        bool hasBalance = address(this).balance > 0;
        bool hasMintedNft = s_currentDrawTicketsMinted > 0;

        upkeepNeeded = timeHasPassed && isOpen && hasBalance && hasMintedNft;
        return (upkeepNeeded, "");
    }

    /* will be automatically called when chainlink calls checkUpkeep and everything passes`*/
    function pickWinner(bytes calldata /* performData */ ) external {
        (bool upkeepNeeded,) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(address(this).balance, s_currentDrawTicketsMinted, s_raffleState);
        }
        s_raffleState = RaffleState.CALCULATING;

        //Request randomness from chainlink
        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest({
            keyHash: i_gasLine,
            subId: i_subscriptionId,
            requestConfirmations: REQUEST_CONFIRMATIONS,
            callbackGasLimit: i_callbackGasLimit,
            numWords: NUM_WORDS,
            extraArgs: VRFV2PlusClient._argsToBytes(
                // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
            )
        });

        // Request random number
        uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
        emit Raffle__RequestRaffleWinner(requestId);
    }

    /*  Will return the result for `requestRandomWords`
        is being called by `VRFConsumerBaseV2Plus::rawFulfillRandomWords` 
     */
    function fulfillRandomWords(uint256, /* requestId */ uint256[] calldata randomWords) internal override {
        /* Only the tickets from the current draw participate
           Lets say the total minted tickets are 200 (ids from 0 to 199)
           And the currentDrawTicketsMinted are 15
           I will get a random number from 0 to 14
           then add that to 185 (totalMintedTickets- s_currentDrawTicketsMinted) = (200 - 15)
           ids from (0, 184)
           And the winner can be with either tokenId 185 up to 199 (the last 15 minted token, which are from the current draw)
        */
        uint256 totalMintedTickets = i_ticketNft.getNumberOfMintedTokens();
        uint256 winningTokenId =
            randomWords[0] % s_currentDrawTicketsMinted + (totalMintedTickets - s_currentDrawTicketsMinted);

        address winner = i_ticketNft.getOwnerOfToken(winningTokenId);

        s_recentWinner = winner;
        s_currentDrawTicketsMinted = 0;
        s_raffleState = RaffleState.OPEN;
        s_lastTimeStamp = block.timestamp;
        s_ownerWithdrawAmount += address(this).balance / 2;

        emit Raffle__PickedWinner(winner);

        (bool success,) = s_recentWinner.call{value: address(this).balance / 2}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
    }

    function withdrawRemainingEth() external onlyOwner {
        (bool success,) = msg.sender.call{value: s_ownerWithdrawAmount}("");

        if (!success) {
            revert Raffle__TransferFailed();
        }
    }

    /**
     * Getter Functions
     */
    function getEntranceFee() external view returns (uint256) {
        return i_ticketPrice;
    }

    function getRecentWinner() external view returns (address) {
        return s_recentWinner;
    }

    function getLastTimeStamp() external view returns (uint256) {
        return s_lastTimeStamp;
    }
}
