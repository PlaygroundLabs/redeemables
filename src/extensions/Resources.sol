// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {TraitRedemption, ConsiderationItem, OfferItem} from "../lib/RedeemablesStructs.sol";
import {ERC1155ShipyardRedeemableMintable} from "./ERC1155ShipyardRedeemableMintable.sol";

contract Resources is ERC1155ShipyardRedeemableMintable {
    constructor(string memory name_, string memory symbol_) ERC1155ShipyardRedeemableMintable(name_, symbol_) {}

    function mintRedemption(
        uint256, /* campaignId */
        address recipient,
        OfferItem calldata offer,
        ConsiderationItem[] calldata, /* consideration */
        TraitRedemption[] calldata /* traitRedemptions */
    ) external override(ERC1155ShipyardRedeemableMintable) {
        _requireValidRedeemablesCaller();
        _mint(recipient, offer.identifierOrCriteria, offer.endAmount, "");
    }

    function mint(address to, uint256 tokenId, uint256 amount) public onlyOwner {
        _mint(to, tokenId, amount, "");
    }
}
