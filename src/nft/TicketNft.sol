// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

contract TicketNft is ERC721 {
    error TicketNft_NotOwner();

    uint256 private s_tokenCounter;

    address private immutable i_owner;
    mapping(address => uint256) private s_playerToTokenId;

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert TicketNft_NotOwner();
        _;
    }

    constructor() ERC721("Ticket NFT", "TN") {
        i_owner = msg.sender;
    }

    function mintnft(address nftReceiver) external onlyOwner returns (uint256) {
        _safeMint(nftReceiver, s_tokenCounter);
        s_playerToTokenId[nftReceiver] = s_tokenCounter;
        return s_tokenCounter++;
    }

    function getTokenIdOfPlayer(address player) external view onlyOwner returns (uint256) {
        return s_playerToTokenId[player];
    }

    function getNumberOfMintedTokens() external view onlyOwner returns (uint256) {
        return s_tokenCounter;
    }

    function getOwnerOfToken(uint256 tokenId) external view onlyOwner returns (address) {
        return ERC721.ownerOf(tokenId);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "data:application/json;base64,";
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return string(
            abi.encodePacked(
                _baseURI(),
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"',
                            name(), // You can add whatever name here
                            '", "description":"An NFT that is used as a ticket in a decentralized Raffle, 100% on Chain!", ',
                            '"attributes": [{"price": "?", "date": "?"}], "tokenId":"',
                            tokenId,
                            '"}'
                        )
                    )
                )
            )
        );
    }
}
