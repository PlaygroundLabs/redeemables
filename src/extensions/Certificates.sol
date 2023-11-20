// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// import {IERC165} from "openzeppelin-contracts/contracts/interfaces/IERC165.sol";
// import {ERC721ConduitPreapproved_Solady} from "shipyard-core/src/tokens/erc721/ERC721ConduitPreapproved_Solady.sol";
// import {ConsiderationItem, OfferItem} from "seaport-types/src/lib/ConsiderationStructs.sol";
// import {Ownable} from "solady/src/auth/Ownable.sol";
// import {ERC7498NFTRedeemables} from "../lib/ERC7498NFTRedeemables.sol";
// import {CampaignParams} from "../lib/RedeemablesStructs.sol";
// import {IRedemptionMintable} from "../interfaces/IRedemptionMintable.sol";
import {ERC1155ShipyardRedeemableMintable} from "./ERC1155ShipyardRedeemableMintable.sol";

// import {IRedemptionMintable} from "../interfaces/IRedemptionMintable.sol";
// import {TraitRedemption} from "../lib/RedeemablesStructs.sol";

contract Certificates is ERC1155ShipyardRedeemableMintable {
    constructor(
        string memory name_,
        string memory symbol_
    ) ERC1155ShipyardRedeemableMintable(name_, symbol_) {}

    function batchSetTrait(
        uint256[] memory tokenIds,
        bytes32 traitKey,
        bytes32[] memory traitValues
    ) public onlyOwner {
        require(
            tokenIds.length == traitValues.length,
            "tokenIds and traitValues values must have the same length"
        );

        for (uint i = 0; i < tokenIds.length; i++) {
            setTrait(tokenIds[i], traitKey, traitValues[i]);
        }
    }

    function mint(
        address to,
        uint256 tokenId,
        uint256 amount
    ) public onlyOwner {
        _mint(to, tokenId, amount, "");
    }

    function adminMint(
        address to,
        uint256 numTokens,
        uint256 amount
    ) public onlyOwner {
        for (uint i = 0; i < numTokens; i++) {
            ++_nextTokenId;
            _mint(to, _nextTokenId - 1, amount, "");
        }
    }
}
