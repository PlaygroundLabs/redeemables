// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC1155ShipyardRedeemableOwnerMintable} from "./ERC1155ShipyardRedeemableOwnerMintable.sol";

import {DynamicTraits} from "shipyard-core/src/dynamic-traits/DynamicTraits.sol";

contract ERC1155ShipyardRedeemableOwnerMintableDynamicTraits is
    ERC1155ShipyardRedeemableOwnerMintable
{
    address[] public allowedTraitSetters;

    constructor(
        string memory name_,
        string memory symbol_,
        address[] memory allowedTraitSetters_
    ) ERC1155ShipyardRedeemableOwnerMintable(name_, symbol_) {}

    function setTrait(
        uint256 tokenId,
        bytes32 traitKey,
        bytes32 value
    ) public virtual override {
        // TODO: commenting out
        // if (!_exists(tokenId)) {
        //     revert TokenDoesNotExist();
        // }

        // TODO: commenting out
        // if (!_isPreapprovedTraitSetter(msg.sender)) {
        //     revert InvalidCaller(msg.sender);
        // }

        DynamicTraits.setTrait(tokenId, traitKey, value);
    }

    function getTraitValue(
        uint256 tokenId,
        bytes32 traitKey
    ) public view virtual override returns (bytes32 traitValue) {
        // TODO: commenting out
        // if (!_exists(tokenId)) {
        //     revert TokenDoesNotExist();
        // }

        traitValue = DynamicTraits.getTraitValue(tokenId, traitKey);
    }

    function _isPreapprovedTraitSetter(
        address traitSetter
    ) internal view returns (bool) {
        for (uint256 i = 0; i < allowedTraitSetters.length; i++) {
            if (allowedTraitSetters[i] == traitSetter) {
                return true;
            }
        }

        return false;
    }
}
