// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Marketplace is Ownable {
    struct Listing {
        address seller;
        uint256 price;
    }

    IERC20 public paymentToken;
    IERC721 public nftContract;

    mapping(uint256 => Listing) public listings;

    event NFTListed(uint256 indexed tokenId, uint256 price, address seller);
    event NFTPurchased(uint256 indexed tokenId, address buyer);

    constructor(address _paymentToken, address _nftContract) Ownable(msg.sender) {
        paymentToken = IERC20(_paymentToken);
        nftContract = IERC721(_nftContract);
    }

    function listNFT(uint256 tokenId, uint256 price) public {
        require(nftContract.ownerOf(tokenId) == msg.sender, "Not the owner");
        require(nftContract.getApproved(tokenId) == address(this), "Marketplace not approved");

        listings[tokenId] = Listing(msg.sender, price);
        emit NFTListed(tokenId, price, msg.sender);
    }

    function purchaseNFT(uint256 tokenId) public {
        Listing memory listedNFT = listings[tokenId];
        require(listedNFT.price > 0, "NFT not listed for sale");

        require(
            paymentToken.transferFrom(msg.sender, listedNFT.seller, listedNFT.price),
            "Payment failed"
        );

        nftContract.safeTransferFrom(listedNFT.seller, msg.sender, tokenId);
        emit NFTPurchased(tokenId, msg.sender);

        delete listings[tokenId];
    }

    function updateNFTPrice(uint256 tokenId, uint256 newPrice) public {
        require(listings[tokenId].seller == msg.sender, "Not the seller");
        listings[tokenId].price = newPrice;
    }
}
