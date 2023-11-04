// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {Test} from "forge-std/Test.sol";
import {ItemType} from "seaport-types/src/lib/ConsiderationEnums.sol";
import {OfferItem, ConsiderationItem} from "seaport-types/src/lib/ConsiderationStructs.sol";
import {CampaignParams, CampaignRequirements, TraitRedemption} from "../src/lib/RedeemablesStructs.sol";
import {BURN_ADDRESS} from "../src/lib/RedeemablesConstants.sol";
import {ERC721RedemptionMintable} from "../src/extensions/ERC721RedemptionMintable.sol";
import {ERC721OwnerMintable} from "../src/test/ERC721OwnerMintable.sol";

// TODO: switched to owner mintable

// import {ERC1155ShipyardRedeemableMintable} from "../src/extensions/ERC1155ShipyardRedeemableMintable.sol";
import {ERC721ShipyardRedeemableMintable} from "../src/extensions/ERC721ShipyardRedeemableMintable.sol";

import {ERC721RedemptionMintable} from "../src/extensions/ERC721RedemptionMintable.sol";
import {ERC721ShipyardRedeemableOwnerMintable} from "../src/test/ERC721ShipyardRedeemableOwnerMintable.sol";
import {ERC1155ShipyardRedeemableOwnerMintable} from "../src/test/ERC1155ShipyardRedeemableOwnerMintable.sol";
import {ERC1155ShipyardRedeemableOwnerMintableDynamicTraits} from "../src/test/ERC1155ShipyardRedeemableOwnerMintableDynamicTraits.sol";

contract DeployAndConfigure1155Receive is Script, Test {
    address CNC_TREASURY = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    bytes32 traitKey = bytes32("certType");
    bytes32 traitValueBlueprint = bytes32(uint256(1));

    // address CNC_TREASURY = BURN_ADDRESS; // TODO: update

    function run() external {
        vm.startBroadcast();

        // bytes32 traitValueBlueprint = bytes32("blue");
        // bytes32 traitValueGoldprint = bytes32("gold");

        address[] memory allowedTraitSetters = new address[](1);
        allowedTraitSetters[0] = msg.sender;

        // make the tokens
        ERC1155ShipyardRedeemableOwnerMintableDynamicTraits certificates = new ERC1155ShipyardRedeemableOwnerMintableDynamicTraits(
                "Certificates",
                "CERTS",
                allowedTraitSetters
            );

        ERC1155ShipyardRedeemableOwnerMintable resources = new ERC1155ShipyardRedeemableOwnerMintable(
                "Resources",
                "RSRCS"
            );

        // TODO: using ERC1155 as placeholder for WETH
        ERC1155ShipyardRedeemableOwnerMintable weth = new ERC1155ShipyardRedeemableOwnerMintable(
                "Wrapped ETH",
                "WETH"
            );

        ERC721ShipyardRedeemableMintable ships = new ERC721ShipyardRedeemableMintable(
                "Ships",
                "SHIPS"
            );

        // Configure the campaign for ships

        // Configure the offers. These are the what the user receives from the redemption
        OfferItem[] memory offer = new OfferItem[](1);
        offer[0] = OfferItem({
            itemType: ItemType.ERC721_WITH_CRITERIA,
            token: address(ships),
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1
        });

        // Configure the considerations. These are the inputs to the redeem,
        // the things the user should must have in order to recieve the offer items
        ConsiderationItem[] memory consideration = new ConsiderationItem[](4);
        consideration[0] = ConsiderationItem({
            itemType: ItemType.ERC1155_WITH_CRITERIA,
            token: address(certificates),
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1,
            recipient: payable(CNC_TREASURY) // TODO: burn address here was failing
        });
        consideration[1] = ConsiderationItem({
            itemType: ItemType.ERC1155,
            token: address(resources),
            identifierOrCriteria: 1,
            startAmount: 100,
            endAmount: 100,
            recipient: payable(CNC_TREASURY)
        });
        consideration[2] = ConsiderationItem({
            itemType: ItemType.ERC1155,
            token: address(resources),
            identifierOrCriteria: 2,
            startAmount: 100,
            endAmount: 100,
            recipient: payable(CNC_TREASURY)
        });
        // TODO: ask Ryan about how to do an ERC20 instead of ERC1155
        consideration[3] = ConsiderationItem({
            itemType: ItemType.ERC1155,
            token: address(weth),
            identifierOrCriteria: 1,
            startAmount: 500,
            endAmount: 500,
            recipient: payable(CNC_TREASURY)
        });

        CampaignRequirements[] memory requirements = new CampaignRequirements[](
            1
        );

        TraitRedemption[] memory traitRedemptions = new TraitRedemption[](1);
        // TODO: can make this does not need to update the trait
        // Right now permissions are commented out in the contract so should work
        // https://github.com/ethereum/ERCs/blob/db0ccb98c7e8c8fd9043d3b4b5fcf1827ef92cec/ERCS/erc-7498.md#metadata-uri
        traitRedemptions[0] = TraitRedemption({
            substandard: 4,
            token: address(certificates),
            traitKey: traitKey,
            traitValue: traitValueBlueprint, // new trait value
            substandardValue: bytes32(uint256(1))
        });

        requirements[0].offer = offer;
        requirements[0].consideration = consideration;
        requirements[0].traitRedemptions = traitRedemptions;

        CampaignParams memory params = CampaignParams({
            requirements: requirements,
            signer: address(0),
            startTime: 0,
            endTime: uint32(block.timestamp + 1_000_000),
            maxCampaignRedemptions: 1_000,
            manager: msg.sender
        });
        ships.createCampaign(
            params,
            "ipfs://QmQjubc6guHReNW5Es5ZrgDtJRwXk2Aia7BkVoLJGaCRqP"
        );

        // To test updateCampaign, update to proper start/end times.
        params.startTime = uint32(block.timestamp);
        params.endTime = uint32(block.timestamp + 1_000_000);
        ships.updateCampaign(1, params, "");

        // Mint some tokens for the redeem ingredients
        certificates.mint(msg.sender, 1, 1); // certificate
        resources.mint(msg.sender, 1, 100); // metal // TODO: shoudl this start at 0 or 1?
        resources.mint(msg.sender, 2, 100); // wood
        weth.mint(msg.sender, 1, 1200); // weth

        certificates.setApprovalForAll(address(ships), true);
        resources.setApprovalForAll(address(ships), true);
        weth.setApprovalForAll(address(ships), true);

        // Set traits
        certificates.setTrait(1, traitKey, traitValueBlueprint);

        // Verify pre-redeem state
        assertEq(certificates.balanceOf(msg.sender, 1), 1);
        assertEq(certificates.balanceOf(CNC_TREASURY, 1), 0);
        assertEq(resources.balanceOf(msg.sender, 1), 100);
        assertEq(resources.balanceOf(msg.sender, 2), 100);
        assertEq(weth.balanceOf(msg.sender, 1), 1200);
        assertEq(ships.balanceOf(CNC_TREASURY), 0);

        // Let's redeem!
        uint256 campaignId = 1;
        uint256 requirementsIndex = 0;
        bytes32 redemptionHash;
        uint256[] memory traitRedemptionTokenIds = new uint256[](1);
        traitRedemptionTokenIds[0] = 1;
        uint256 salt;
        bytes memory signature;
        bytes memory data = abi.encode(
            campaignId,
            requirementsIndex,
            redemptionHash,
            traitRedemptionTokenIds,
            salt,
            signature
        );

        uint256[] memory tokenIds = new uint256[](4);
        tokenIds[0] = 1;
        tokenIds[1] = 1;
        tokenIds[2] = 2;
        tokenIds[3] = 1;

        ships.redeem(tokenIds, msg.sender, data);

        // Verify post-redeem state
        // assertEq(certificates.balanceOf(msg.sender, 1), 0);
        // assertEq(certificates.balanceOf(CNC_TREASURY, 1), 1);
        assertEq(resources.balanceOf(msg.sender, 1), 0);
        assertEq(resources.balanceOf(msg.sender, 2), 0);
        assertEq(resources.balanceOf(CNC_TREASURY, 1), 100);
        assertEq(resources.balanceOf(CNC_TREASURY, 2), 100);
        assertEq(weth.balanceOf(msg.sender, 1), 700);
        assertEq(weth.balanceOf(CNC_TREASURY, 1), 500);
        assertEq(ships.ownerOf(1), msg.sender);

        // Confirm they can't redeem again because they don't have enough ingreidents
        // TODO: not sure how to do this outside of a test
        // vm.expectRevert()
        // ships.redeem(tokenIds, msg.sender, data);
    }
}
