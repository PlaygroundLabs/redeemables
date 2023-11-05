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
    bytes32 traitValueGoldprint = bytes32(uint256(2));
    uint32 campaignStartTime = 0; //  seconds since epoch
    uint32 campaignEndTime = 2000000000; // seconds since epoch
    uint32 maxCampaignRedemptions = 1_000_000_000;

    function setUpBlueprintAndGoldprintCampaigns(
        address shipsAddr,
        address certificatesAddr,
        address resourcesAddr,
        address wethAddr
    ) public {
        // Creates two campaigns for the ships contract. The first is
        // for blueprints which consider the certificate, metal, wood, and weth.
        // The second is considers just the certificate. The offer is always a ship.
        // DynamicTraits are also checked on the ship and must correspond to blueprint
        // and goldprint for the respective redeem.
        //
        // Offers: What the user receives from the redemption
        // Considerations: what the user inputs to the redemption
        // TraitRedemptions: qualities of the considerations' traits that must be met

        ERC721ShipyardRedeemableMintable ships = ERC721ShipyardRedeemableMintable(
                shipsAddr
            );

        //////////////////////////
        /// Blueprint Campaign ///
        //////////////////////////
        OfferItem[] memory offer = new OfferItem[](1);
        offer[0] = OfferItem({
            itemType: ItemType.ERC721_WITH_CRITERIA,
            token: address(ships),
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1
        });

        ConsiderationItem[] memory consideration = new ConsiderationItem[](4);
        consideration[0] = ConsiderationItem({
            itemType: ItemType.ERC1155_WITH_CRITERIA,
            token: address(certificatesAddr),
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1,
            recipient: payable(BURN_ADDRESS) // TODO: the burn is failing and it's transferring to the burn address
        });

        consideration[1] = ConsiderationItem({
            itemType: ItemType.ERC1155,
            token: address(resourcesAddr),
            identifierOrCriteria: 1,
            startAmount: 100,
            endAmount: 100,
            recipient: payable(CNC_TREASURY)
        });

        consideration[2] = ConsiderationItem({
            itemType: ItemType.ERC1155,
            token: address(resourcesAddr),
            identifierOrCriteria: 2,
            startAmount: 100,
            endAmount: 100,
            recipient: payable(CNC_TREASURY)
        });

        // TODO: ask Ryan about how to do an ERC20 instead of ERC1155
        consideration[3] = ConsiderationItem({
            itemType: ItemType.ERC1155,
            token: address(wethAddr),
            identifierOrCriteria: 1,
            startAmount: 500,
            endAmount: 500,
            recipient: payable(CNC_TREASURY)
        });

        // TODO: can make this does not need to update the trait
        // Right now permissions are commented out in the contract so should work
        // https://github.com/ethereum/ERCs/blob/db0ccb98c7e8c8fd9043d3b4b5fcf1827ef92cec/ERCS/erc-7498.md#metadata-uri
        TraitRedemption[] memory traitRedemptions = new TraitRedemption[](1);
        traitRedemptions[0] = TraitRedemption({
            substandard: 4, // an indicator integer
            token: address(certificatesAddr),
            traitKey: traitKey,
            traitValue: traitValueBlueprint, // new trait value
            substandardValue: traitValueBlueprint // required previous value
        });

        // Create the first campaign for blueprints
        CampaignRequirements[] memory requirements = new CampaignRequirements[](
            1
        );
        requirements[0].offer = offer;
        requirements[0].consideration = consideration;
        requirements[0].traitRedemptions = traitRedemptions;

        CampaignParams memory params = CampaignParams({
            requirements: requirements,
            signer: address(0),
            startTime: campaignStartTime,
            endTime: campaignEndTime,
            maxCampaignRedemptions: maxCampaignRedemptions,
            manager: msg.sender
        });

        uint campaignId1 = ships.createCampaign(
            params,
            "ipfs://QmQjubc6guHReNW5Es5ZrgDtJRwXk2Aia7BkVoLJGaCRqP"
        );
        assertEq(campaignId1, 1);

        //////////////////////////
        /// Goldprint Campaign ///
        //////////////////////////

        OfferItem[] memory offer2 = new OfferItem[](1);
        offer2[0] = OfferItem({
            itemType: ItemType.ERC721_WITH_CRITERIA,
            token: address(ships),
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1
        });

        ConsiderationItem[] memory consideration2 = new ConsiderationItem[](1);
        consideration2[0] = ConsiderationItem({
            itemType: ItemType.ERC1155_WITH_CRITERIA,
            token: address(certificatesAddr),
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1,
            recipient: payable(BURN_ADDRESS) // TODO: the burn is failing and it's transferring to the burn address
        });

        TraitRedemption[] memory traitRedemptions2 = new TraitRedemption[](1);
        // TODO: can make this does not need to update the trait
        // Right now permissions are commented out in the contract so should work
        // https://github.com/ethereum/ERCs/blob/db0ccb98c7e8c8fd9043d3b4b5fcf1827ef92cec/ERCS/erc-7498.md#metadata-uri
        traitRedemptions2[0] = TraitRedemption({
            substandard: 4, // an indicator integer
            token: address(certificatesAddr),
            traitKey: traitKey,
            traitValue: traitValueGoldprint, // new trait value
            substandardValue: traitValueGoldprint // required previous value
        });

        // Create the second campaign for goldprint
        CampaignRequirements[]
            memory requirements2 = new CampaignRequirements[](1);
        requirements2[0].offer = offer2;
        requirements2[0].consideration = consideration2;
        requirements2[0].traitRedemptions = traitRedemptions2;
        CampaignParams memory params2 = CampaignParams({
            requirements: requirements2,
            signer: address(0),
            startTime: campaignStartTime,
            endTime: campaignEndTime,
            maxCampaignRedemptions: maxCampaignRedemptions,
            manager: msg.sender
        });

        // uint campaignId2 = ERC721ShipyardRedeemableMintable(ships)
        uint campaignId2 = ships.createCampaign(
            params2,
            "ipfs://QmQjubc6guHReNW5Es5ZrgDtJRwXk2Aia7BkVoLJGaCRqP"
        );

        assertEq(campaignId2, 2);
    }

    function run() external {
        vm.startBroadcast();

        address[] memory allowedTraitSetters = new address[](1);
        allowedTraitSetters[0] = msg.sender;

        // make the tokens
        // TODO: traits might already be set on here. See ERC721ShipyardRedeemable.sol
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

        setUpBlueprintAndGoldprintCampaigns(
            address(ships),
            address(certificates),
            address(resources),
            address(weth)
        );

        // Mint some tokens for the redeem ingredients
        certificates.mint(msg.sender, 1, 1); // certificate
        resources.mint(msg.sender, 1, 100); // metal
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
        assertEq(ships.ownerOf(1), msg.sender);
        assertEq(weth.balanceOf(msg.sender, 1), 700);
        assertEq(weth.balanceOf(CNC_TREASURY, 1), 500);

        // These are requiring viaIR=true in found.toml for reasons I don't understand.
        assertEq(certificates.balanceOf(msg.sender, 1), 0);
        assertEq(certificates.balanceOf(CNC_TREASURY, 1), 0);
        assertEq(resources.balanceOf(msg.sender, 1), 0);
        assertEq(resources.balanceOf(msg.sender, 2), 0);
        assertEq(resources.balanceOf(CNC_TREASURY, 1), 100);
        assertEq(resources.balanceOf(CNC_TREASURY, 2), 100);

        // Mint tokens for the goldprint campaign
        certificates.mint(msg.sender, 7, 1); // certificate
        certificates.setTrait(7, traitKey, traitValueGoldprint);
        assertEq(certificates.getTraitValue(7, traitKey), traitValueGoldprint);

        uint256[] memory traitRedemptionTokenIds2 = new uint256[](1);
        traitRedemptionTokenIds2[0] = 7;
        bytes memory data2 = abi.encode(
            2, // campaing id. I think this isn't being picked up by redeem
            requirementsIndex, // 0 because only one requirements
            redemptionHash,
            traitRedemptionTokenIds2,
            salt,
            signature
        );

        uint256[] memory tokenIds2 = new uint256[](1);
        tokenIds2[0] = 7;

        assertEq(certificates.balanceOf(msg.sender, 7), 1);

        ships.redeem(tokenIds2, msg.sender, data2);
        assertEq(ships.ownerOf(2), msg.sender);

        // Verify post-redeem state
        // These are requiring viaIR=true in found.toml for reasons I don't understand.
        assertEq(certificates.balanceOf(msg.sender, 7), 0);
        assertEq(certificates.balanceOf(CNC_TREASURY, 7), 0);
        assertEq(ships.ownerOf(2), msg.sender);

        // Confirm they can't redeem again because they don't have enough ingreidents
        // TODO: not sure how to do this outside of a test
        // vm.expectRevert()
        // ships.redeem(tokenIds, msg.sender, data);
    }
}
