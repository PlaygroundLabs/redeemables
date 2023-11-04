// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {Test} from "forge-std/Test.sol";
import {ItemType} from "seaport-types/src/lib/ConsiderationEnums.sol";
import {OfferItem, ConsiderationItem} from "seaport-types/src/lib/ConsiderationStructs.sol";
import {CampaignParams, CampaignRequirements} from "../src/lib/RedeemablesStructs.sol";
import {BURN_ADDRESS} from "../src/lib/RedeemablesConstants.sol";
import {ERC721RedemptionMintable} from "../src/extensions/ERC721RedemptionMintable.sol";
import {ERC721OwnerMintable} from "../src/test/ERC721OwnerMintable.sol";
import {ERC1155ShipyardRedeemableMintable} from "../src/extensions/ERC1155ShipyardRedeemableMintable.sol";
import {ERC721ShipyardRedeemableMintable} from "../src/extensions/ERC721ShipyardRedeemableMintable.sol";

contract DeployAndConfigure1155Receive is Script, Test {
    function run() external {
        vm.startBroadcast();

        address redeemToken = 0x1eCC76De3f9E4e9f8378f6ade61A02A10f976c45;
        ERC1155ShipyardRedeemableMintable certificate = new ERC1155ShipyardRedeemableMintable(
                "Certificates",
                "CERTS"
            );

        ERC1155ShipyardRedeemableMintable resources = new ERC1155ShipyardRedeemableMintable(
                "Resources",
                "RSRCS"
            );

        ERC721ShipyardRedeemableMintable resources = new ERC721ShipyardRedeemableMintable(
                "Ships",
                "SHIPS"
            );

        // Configure the campaign.
    }
}
