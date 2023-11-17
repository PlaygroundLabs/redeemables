// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {Test} from "forge-std/Test.sol";
import {ItemType} from "seaport-types/src/lib/ConsiderationEnums.sol";
import {OfferItem, ConsiderationItem} from "seaport-types/src/lib/ConsiderationStructs.sol";
import {Campaign, CampaignParams, CampaignRequirements, TraitRedemption} from "../src/lib/RedeemablesStructs.sol";
import {BURN_ADDRESS} from "../src/lib/RedeemablesConstants.sol";

import {TestERC20} from "../test/utils/mocks/TestERC20.sol";
import {ERC721ShipyardRedeemableMintable} from "../src/extensions/ERC721ShipyardRedeemableMintable.sol";
import {ERC1155ShipyardRedeemableMintable} from "../src/extensions/ERC1155ShipyardRedeemableMintable.sol";
import {ERC721ShipyardRedeemableMintableRentable} from "../src/extensions/ERC721ShipyardRedeemableMintableRentable.sol";

contract CNCContractScript is Script, Test {
    address CNC_TREASURY = 0x2DC39C543028933ea5e45851Fa84ad8F95C4c1DE; // TODO: update me later

    // 0x6365727454797065000000000000000000000000000000000000000000000000
    bytes32 traitKey = bytes32("certType");

    bytes32 traitValueWraithBlueprint = bytes32(uint256(1));
    bytes32 traitValueWraithGoldprint = bytes32(uint256(2));
    bytes32 traitValueClockworkBlueprint = bytes32(uint256(3));
    bytes32 traitValueClockworkGoldprint = bytes32(uint256(4));
    bytes32 traitValueT1Lumber = bytes32(uint256(5));
    bytes32 traitValueT2Lumber = bytes32(uint256(6));
    bytes32 traitValueT3Lumber = bytes32(uint256(7));
    bytes32 traitValueT1Ore = bytes32(uint256(8));
    bytes32 traitValueT2Ore = bytes32(uint256(9));
    bytes32 traitValueT3Ore = bytes32(uint256(10));
    bytes32 traitValueHat1 = bytes32(uint256(11)); // straw hat
    bytes32 traitValueHat2 = bytes32(uint256(12)); // horned helm
    bytes32 traitValueHat3 = bytes32(uint256(13)); // tinkerer's goggles
    bytes32 traitValueEyepiece1 = bytes32(uint256(14)); // eyepatch
    bytes32 traitValueEyepiece2 = bytes32(uint256(15)); // carnival mask
    bytes32 traitValueEyepiece3 = bytes32(uint256(16)); // rose tinted moncole
    bytes32 traitValueCannon1 = bytes32(uint256(17)); // star cannon
    bytes32 traitValueCannon2 = bytes32(uint256(18)); // pink party cannon
    bytes32 traitValueCannon3 = bytes32(uint256(19)); // skeletal cannon

    uint32 t1LumberTokenId = 1;
    uint32 t2LumberTokenId = 2;
    uint32 t3LumberTokenId = 3;
    uint32 t1OreTokenId = 4;
    uint32 t2OreTokenId = 5;
    uint32 t3OreTokenId = 6;
    uint32 shipLumberConsidered = 10_000;
    uint32 shipOreConsidered = 7_500;
    uint32 wethConsidered = 500;
    uint32 resourcesOffered = 10_000;

    uint32 campaignStartTime = 1698796800; //  seconds since epoch
    uint32 campaignEndTime = 1733011200; // seconds since epoch
    uint32 maxCampaignRedemptions = 6500; // this is specifically for the lootbox

    function testLootboxRedeem(
        address lootboxesAdddr,
        address certificatesAddr
    ) public {
        uint campaignId = 1;
        uint tokenId = 1;
        ERC721ShipyardRedeemableMintable lootboxes = ERC721ShipyardRedeemableMintable(
                lootboxesAdddr
            );

        ERC1155ShipyardRedeemableMintable certificates = ERC1155ShipyardRedeemableMintable(
                certificatesAddr
            );

        // lootboxes.mint(msg.sender, tokenId); // TODO: uncomment

        assertEq(lootboxes.balanceOf(msg.sender), 1); // confirm they have the lootbox
        assertEq(certificates.balanceOf(msg.sender, 1), 0);
        assertEq(certificates.balanceOf(msg.sender, 2), 0);
        assertEq(certificates.balanceOf(msg.sender, 3), 0);
        assertEq(certificates.balanceOf(msg.sender, 4), 0);
        assertEq(certificates.balanceOf(msg.sender, 5), 0);
        assertEq(certificates.balanceOf(msg.sender, 6), 0);

        uint256[] memory traitRedemptionTokenIds = new uint256[](0);
        bytes memory data = abi.encode(
            campaignId,
            0,
            bytes32(0),
            traitRedemptionTokenIds,
            uint256(0),
            bytes("")
        );

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;

        certificates.redeem(tokenIds, msg.sender, data);

        // confirm msg.sender got the right number of certs
        assertEq(certificates.balanceOf(msg.sender, 1), 1);
        assertEq(certificates.balanceOf(msg.sender, 2), 1);
        assertEq(certificates.balanceOf(msg.sender, 3), 1);
        assertEq(certificates.balanceOf(msg.sender, 4), 1);
        assertEq(certificates.balanceOf(msg.sender, 5), 1);
        assertEq(certificates.balanceOf(msg.sender, 6), 0);

        // confirm they no longer have the lootbox
        assertEq(lootboxes.balanceOf(msg.sender), 0);
    }

    function testWraithRedeems(
        address shipsAddr,
        address certificatesAddr,
        address resourcesAddr,
        address wethAddr
    ) public {
        // This tests redeeming the wraith blueprint and goldprint

        ERC721ShipyardRedeemableMintable ships = ERC721ShipyardRedeemableMintable(
                shipsAddr
            );
        ERC1155ShipyardRedeemableMintable certificates = ERC1155ShipyardRedeemableMintable(
                certificatesAddr
            );
        ERC1155ShipyardRedeemableMintable resources = ERC1155ShipyardRedeemableMintable(
                resourcesAddr
            );

        TestERC20 weth = TestERC20(wethAddr);

        // Wraith Blueprint Section

        // Mint some tokens for the redeem ingredients
        certificates.mint(msg.sender, 1, 1); // certificate
        resources.mint(msg.sender, t3LumberTokenId, 30_000);
        resources.mint(msg.sender, t3OreTokenId, 30_000);
        weth.mint(msg.sender, 20_000); // weth
        certificates.setApprovalForAll(address(ships), true);
        resources.setApprovalForAll(address(ships), true);
        weth.approve(address(ships), 99999999);
        certificates.setTrait(1, traitKey, traitValueWraithBlueprint);

        // Verify pre-redeem state
        assertEq(certificates.balanceOf(msg.sender, 1), 1);
        assertEq(certificates.balanceOf(CNC_TREASURY, 1), 0);
        assertEq(resources.balanceOf(msg.sender, t3LumberTokenId), 30_000);
        assertEq(resources.balanceOf(msg.sender, t3OreTokenId), 30_000);
        assertEq(weth.balanceOf(msg.sender), 20_000);
        assertEq(ships.balanceOf(CNC_TREASURY), 0);

        // Let's redeem!
        uint256 requirementsIndex = 0;
        bytes32 redemptionHash;
        uint256[] memory traitRedemptionTokenIds = new uint256[](1);
        traitRedemptionTokenIds[0] = 1;
        uint256 salt;
        bytes memory signature;
        bytes memory data = abi.encode(
            1, // wraithBlueprintCampaignId
            requirementsIndex,
            redemptionHash,
            traitRedemptionTokenIds,
            salt,
            signature
        );

        uint256[] memory tokenIds = new uint256[](4);
        tokenIds[0] = 1;
        tokenIds[1] = t3LumberTokenId;
        tokenIds[2] = t3OreTokenId;
        tokenIds[3] = 1;

        ships.redeem(tokenIds, msg.sender, data);

        // Verify post-redeem state
        assertEq(ships.ownerOf(1), msg.sender);
        assertEq(weth.balanceOf(msg.sender), 20_000 - wethConsidered);
        assertEq(weth.balanceOf(CNC_TREASURY), wethConsidered);

        assertEq(certificates.balanceOf(msg.sender, 1), 0);
        assertEq(certificates.balanceOf(CNC_TREASURY, 1), 0);
        assertEq(
            resources.balanceOf(msg.sender, t3LumberTokenId),
            30_000 - shipLumberConsidered
        );
        assertEq(
            resources.balanceOf(msg.sender, t3OreTokenId),
            30_000 - shipOreConsidered
        );
        assertEq(
            resources.balanceOf(CNC_TREASURY, t3LumberTokenId),
            shipLumberConsidered
        );
        assertEq(
            resources.balanceOf(CNC_TREASURY, t3OreTokenId),
            shipOreConsidered
        );

        // Wraith Goldprint Section

        certificates.mint(msg.sender, 7, 1); // certificate
        certificates.setTrait(7, traitKey, traitValueWraithGoldprint);
        assertEq(
            certificates.getTraitValue(7, traitKey),
            traitValueWraithGoldprint
        );

        uint256[] memory traitRedemptionTokenIds2 = new uint256[](1);
        traitRedemptionTokenIds2[0] = 7;
        bytes memory data2 = abi.encode(
            2, // wraithBlueprintCampaignId
            requirementsIndex, // 0 because only one requirements
            0x0,
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
    }

    function doARedeem(
        address shipsAddr,
        uint256 tokenToRedeem,
        uint256 campaignId
    ) public {
        // This was a helper function for testing a redeem
        // on arb1 to already deployed contracts
        // This was specificaly used for a goldprint

        uint256[] memory traitRedemptionTokenIds = new uint256[](1);
        traitRedemptionTokenIds[0] = tokenToRedeem;

        bytes memory data = abi.encode(
            campaignId,
            0,
            0x0,
            traitRedemptionTokenIds,
            0x0,
            0x0
        );

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenToRedeem;

        ERC721ShipyardRedeemableMintable(shipsAddr).redeem(
            tokenIds,
            msg.sender,
            data
        );
    }

    function setUpCertificatesCampaign(
        address lootboxesAddr,
        address certificatesAddr
    ) public returns (uint256) {
        // Setups the certificates campaign.
        // A single lootbox should yield a certificate.

        ERC1155ShipyardRedeemableMintable certificates = ERC1155ShipyardRedeemableMintable(
                certificatesAddr
            );

        OfferItem[] memory offer = new OfferItem[](5);
        offer[0] = OfferItem({
            itemType: ItemType.ERC1155_WITH_CRITERIA,
            token: certificatesAddr,
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1
        });
        offer[1] = OfferItem({
            itemType: ItemType.ERC1155_WITH_CRITERIA,
            token: certificatesAddr,
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1
        });
        offer[2] = OfferItem({
            itemType: ItemType.ERC1155_WITH_CRITERIA,
            token: certificatesAddr,
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1
        });
        offer[3] = OfferItem({
            itemType: ItemType.ERC1155_WITH_CRITERIA,
            token: certificatesAddr,
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1
        });
        offer[4] = OfferItem({
            itemType: ItemType.ERC1155_WITH_CRITERIA,
            token: certificatesAddr,
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1
        });

        ConsiderationItem[] memory consideration = new ConsiderationItem[](1);
        consideration[0] = ConsiderationItem({
            itemType: ItemType.ERC721_WITH_CRITERIA,
            token: lootboxesAddr,
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1,
            recipient: payable(BURN_ADDRESS)
        });

        // Create the second campaign for goldprint
        CampaignRequirements[] memory requirements = new CampaignRequirements[](
            1
        );
        requirements[0].offer = offer;
        requirements[0].consideration = consideration;

        CampaignParams memory params = CampaignParams({
            signer: address(0),
            startTime: campaignStartTime,
            endTime: campaignEndTime,
            maxCampaignRedemptions: maxCampaignRedemptions,
            manager: msg.sender
        });

        Campaign memory campaign = Campaign({
            params: params,
            requirements: requirements
        });

        uint campaignId = certificates.createCampaign(
            campaign,
            "ipfs://Qmd1svWLxdjRUCxDCv6i6MFZtcU6SY56mD6JM8Ds1ZrXPB"
        );
        // uint campaignId = 1;
        // certificates.updateCampaign(
        //     campaignId,
        //     params,
        //     "ipfs://Qmd1svWLxdjRUCxDCv6i6MFZtcU6SY56mD6JM8Ds1ZrXPB"
        // );
        return campaignId;
    }

    function setUpWraithBlueprintCampaign(
        address shipsAddr,
        address certificatesAddr,
        address resourcesAddr,
        address wethAddr
    ) public returns (uint256) {
        ERC721ShipyardRedeemableMintable ships = ERC721ShipyardRedeemableMintable(
                shipsAddr
            );

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
            recipient: payable(BURN_ADDRESS)
        });

        consideration[1] = ConsiderationItem({
            itemType: ItemType.ERC1155,
            token: address(resourcesAddr),
            identifierOrCriteria: t3LumberTokenId,
            startAmount: shipLumberConsidered,
            endAmount: shipLumberConsidered,
            recipient: payable(CNC_TREASURY)
        });

        consideration[2] = ConsiderationItem({
            itemType: ItemType.ERC1155,
            token: address(resourcesAddr),
            identifierOrCriteria: t3OreTokenId,
            startAmount: shipOreConsidered,
            endAmount: shipOreConsidered,
            recipient: payable(CNC_TREASURY)
        });

        consideration[3] = ConsiderationItem({
            itemType: ItemType.ERC20,
            token: wethAddr,
            identifierOrCriteria: 0,
            startAmount: wethConsidered,
            endAmount: wethConsidered,
            recipient: payable(CNC_TREASURY)
        });

        TraitRedemption[] memory traitRedemptions = new TraitRedemption[](1);
        traitRedemptions[0] = TraitRedemption({
            substandard: 4, // an indicator integer
            token: address(certificatesAddr),
            traitKey: traitKey,
            traitValue: traitValueWraithBlueprint, // new trait value
            substandardValue: traitValueWraithBlueprint // required previous value
        });

        // Create the first campaign for blueprints
        CampaignRequirements[] memory requirements = new CampaignRequirements[](
            1
        );
        requirements[0].offer = offer;
        requirements[0].consideration = consideration;
        requirements[0].traitRedemptions = traitRedemptions;

        CampaignParams memory params = CampaignParams({
            signer: address(0),
            startTime: campaignStartTime,
            endTime: campaignEndTime,
            maxCampaignRedemptions: maxCampaignRedemptions,
            manager: msg.sender
        });

        Campaign memory campaign = Campaign({
            params: params,
            requirements: requirements
        });

        uint campaignId = ships.createCampaign(
            campaign,
            "ipfs://Qmd1svWLxdjRUCxDCv6i6MFZtcU6SY56mD6JM8Ds1ZrXPB"
        );

        return campaignId;
    }

    function setUpWraithGoldprintCampaign(
        address shipsAddr,
        address certificatesAddr,
        address resourcesAddr,
        address wethAddr
    ) public returns (uint256) {
        // Setups the goldprint campaign for the wraith ship
        // Considerations:
        // - certificate with the goldprint dynamic trait
        // - offer: a ship
        ERC721ShipyardRedeemableMintable ships = ERC721ShipyardRedeemableMintable(
                shipsAddr
            );

        OfferItem[] memory offer = new OfferItem[](1);
        offer[0] = OfferItem({
            itemType: ItemType.ERC721_WITH_CRITERIA,
            token: address(ships),
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1
        });

        ConsiderationItem[] memory consideration = new ConsiderationItem[](1);
        consideration[0] = ConsiderationItem({
            itemType: ItemType.ERC1155_WITH_CRITERIA,
            token: address(certificatesAddr),
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1,
            recipient: payable(BURN_ADDRESS)
        });

        TraitRedemption[] memory traitRedemptions = new TraitRedemption[](1);
        traitRedemptions[0] = TraitRedemption({
            substandard: 4, // an indicator integer
            token: address(certificatesAddr),
            traitKey: traitKey,
            traitValue: traitValueWraithGoldprint, // new trait value
            substandardValue: traitValueWraithGoldprint // required previous value
        });

        // Create the second campaign for goldprint
        CampaignRequirements[] memory requirements = new CampaignRequirements[](
            1
        );
        requirements[0].offer = offer;
        requirements[0].consideration = consideration;
        requirements[0].traitRedemptions = traitRedemptions;

        CampaignParams memory params = CampaignParams({
            signer: address(0),
            startTime: campaignStartTime,
            endTime: campaignEndTime,
            maxCampaignRedemptions: maxCampaignRedemptions,
            manager: msg.sender
        });

        Campaign memory campaign = Campaign({
            params: params,
            requirements: requirements
        });

        uint campaignId = ships.createCampaign(
            campaign,
            "ipfs://QmQjubc6guHReNW5Es5ZrgDtJRwXk2Aia7BkVoLJGaCRqP"
        );

        return campaignId;
    }

    function setUpClockworkBlueprintCampaign(
        address shipsAddr,
        address certificatesAddr,
        address resourcesAddr,
        address wethAddr
    ) public returns (uint256) {
        // Creates a campaigns for clockwork ship from a blueprint.

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
            recipient: payable(BURN_ADDRESS)
        });

        consideration[1] = ConsiderationItem({
            itemType: ItemType.ERC1155,
            token: address(resourcesAddr),
            identifierOrCriteria: t2LumberTokenId,
            startAmount: shipLumberConsidered,
            endAmount: shipLumberConsidered,
            recipient: payable(CNC_TREASURY)
        });

        consideration[2] = ConsiderationItem({
            itemType: ItemType.ERC1155,
            token: address(resourcesAddr),
            identifierOrCriteria: t2OreTokenId,
            startAmount: shipOreConsidered,
            endAmount: shipOreConsidered,
            recipient: payable(CNC_TREASURY)
        });

        consideration[3] = ConsiderationItem({
            itemType: ItemType.ERC20,
            token: wethAddr,
            identifierOrCriteria: 0,
            startAmount: wethConsidered,
            endAmount: wethConsidered,
            recipient: payable(CNC_TREASURY)
        });

        TraitRedemption[] memory traitRedemptions = new TraitRedemption[](1);
        traitRedemptions[0] = TraitRedemption({
            substandard: 4, // an indicator integer
            token: address(certificatesAddr),
            traitKey: traitKey,
            traitValue: traitValueClockworkBlueprint, // new trait value
            substandardValue: traitValueClockworkBlueprint // required previous value
        });

        // Create the first campaign for blueprints
        CampaignRequirements[] memory requirements = new CampaignRequirements[](
            1
        );
        requirements[0].offer = offer;
        requirements[0].consideration = consideration;
        requirements[0].traitRedemptions = traitRedemptions;

        CampaignParams memory params = CampaignParams({
            signer: address(0),
            startTime: campaignStartTime,
            endTime: campaignEndTime,
            maxCampaignRedemptions: maxCampaignRedemptions,
            manager: msg.sender
        });

        Campaign memory campaign = Campaign({
            params: params,
            requirements: requirements
        });

        uint campaignId = ships.createCampaign(
            campaign,
            "ipfs://QmQjubc6guHReNW5Es5ZrgDtJRwXk2Aia7BkVoLJGaCRqP"
        );
        return campaignId;
    }

    function setUpClockworkGoldprintCampaign(
        address shipsAddr,
        address certificatesAddr,
        address resourcesAddr,
        address wethAddr
    ) public returns (uint256) {
        // Setups the goldprint campaign
        // Considerations:
        // - certificate with the goldprint dynamic trait
        // - offer: a ship
        ERC721ShipyardRedeemableMintable ships = ERC721ShipyardRedeemableMintable(
                shipsAddr
            );

        OfferItem[] memory offer = new OfferItem[](1);
        offer[0] = OfferItem({
            itemType: ItemType.ERC721_WITH_CRITERIA,
            token: address(ships),
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1
        });

        ConsiderationItem[] memory consideration = new ConsiderationItem[](1);
        consideration[0] = ConsiderationItem({
            itemType: ItemType.ERC1155_WITH_CRITERIA,
            token: address(certificatesAddr),
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1,
            recipient: payable(BURN_ADDRESS)
        });

        TraitRedemption[] memory traitRedemptions = new TraitRedemption[](1);
        traitRedemptions[0] = TraitRedemption({
            substandard: 4, // an indicator integer
            token: address(certificatesAddr),
            traitKey: traitKey,
            traitValue: traitValueClockworkGoldprint, // new trait value
            substandardValue: traitValueClockworkGoldprint // required previous value
        });

        // Create the second campaign for goldprint
        CampaignRequirements[] memory requirements = new CampaignRequirements[](
            1
        );
        requirements[0].offer = offer;
        requirements[0].consideration = consideration;
        requirements[0].traitRedemptions = traitRedemptions;
        CampaignParams memory params = CampaignParams({
            signer: address(0),
            startTime: campaignStartTime,
            endTime: campaignEndTime,
            maxCampaignRedemptions: maxCampaignRedemptions,
            manager: msg.sender
        });

        Campaign memory campaign = Campaign({
            params: params,
            requirements: requirements
        });

        uint campaignId = ships.createCampaign(
            campaign,
            "ipfs://QmQjubc6guHReNW5Es5ZrgDtJRwXk2Aia7BkVoLJGaCRqP"
        );

        return campaignId;
    }

    function setUpShipCampaigns(
        address shipsAddr,
        address certificatesAddr,
        address resourcesAddr,
        address wethAddr
    ) public {
        // Sets up all four ship campaigns
        setUpWraithBlueprintCampaign(
            shipsAddr,
            certificatesAddr,
            resourcesAddr,
            wethAddr
        );

        setUpWraithGoldprintCampaign(
            shipsAddr,
            certificatesAddr,
            resourcesAddr,
            wethAddr
        );

        setUpClockworkBlueprintCampaign(
            shipsAddr,
            certificatesAddr,
            resourcesAddr,
            wethAddr
        );

        setUpClockworkGoldprintCampaign(
            shipsAddr,
            certificatesAddr,
            resourcesAddr,
            wethAddr
        );
    }

    function setUpResourcesCampaign(
        address certificatesAddr,
        address resourcesAddr,
        bytes32 traitValue,
        uint32 resourcesTokenId,
        uint32 resourcesAmount
    ) public returns (uint256) {
        // Sets up a single campaign for resources given the parameters
        ERC1155ShipyardRedeemableMintable resources = ERC1155ShipyardRedeemableMintable(
                resourcesAddr
            );

        OfferItem[] memory offer = new OfferItem[](1);
        offer[0] = OfferItem({
            itemType: ItemType.ERC1155_WITH_CRITERIA,
            token: resourcesAddr,
            identifierOrCriteria: resourcesTokenId,
            startAmount: resourcesAmount,
            endAmount: resourcesAmount
        });

        ConsiderationItem[] memory consideration = new ConsiderationItem[](1);
        consideration[0] = ConsiderationItem({
            itemType: ItemType.ERC1155_WITH_CRITERIA,
            token: address(certificatesAddr),
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1,
            recipient: payable(BURN_ADDRESS)
        });

        TraitRedemption[] memory traitRedemptions = new TraitRedemption[](1);
        traitRedemptions[0] = TraitRedemption({
            substandard: 4, // an indicator integer
            token: address(certificatesAddr),
            traitKey: traitKey,
            traitValue: traitValue, // new trait value
            substandardValue: traitValue // required previous value
        });

        // Create the second campaign for goldprint
        CampaignRequirements[] memory requirements = new CampaignRequirements[](
            1
        );
        requirements[0].offer = offer;
        requirements[0].consideration = consideration;
        requirements[0].traitRedemptions = traitRedemptions;
        CampaignParams memory params = CampaignParams({
            signer: address(0),
            startTime: campaignStartTime,
            endTime: campaignEndTime,
            maxCampaignRedemptions: maxCampaignRedemptions,
            manager: msg.sender
        });

        Campaign memory campaign = Campaign({
            params: params,
            requirements: requirements
        });

        uint256 campaignId = ERC1155ShipyardRedeemableMintable(resourcesAddr)
            .createCampaign(campaign, "uri://");
        return campaignId;
    }

    function setUpResourcesCampaigns(
        address resourcesAddr,
        address certificatesAddr
    ) public {
        // Sets up all the resources campaigns
        setUpResourcesCampaign( // t1 lumber
            certificatesAddr,
            resourcesAddr,
            traitValueT1Lumber,
            t1LumberTokenId,
            resourcesOffered
        );
        setUpResourcesCampaign( // t2 lumber
            certificatesAddr,
            resourcesAddr,
            traitValueT2Lumber,
            t2LumberTokenId,
            resourcesOffered
        );
        setUpResourcesCampaign( // t3 lumber
            certificatesAddr,
            resourcesAddr,
            traitValueT3Lumber,
            t3LumberTokenId,
            resourcesOffered
        );
        setUpResourcesCampaign( // t1 ore
            certificatesAddr,
            resourcesAddr,
            traitValueT1Ore,
            t1OreTokenId,
            resourcesOffered
        );
        setUpResourcesCampaign( // t2 ore
            certificatesAddr,
            resourcesAddr,
            traitValueT2Ore,
            t2OreTokenId,
            resourcesOffered
        );
        setUpResourcesCampaign( // t3 ore
            certificatesAddr,
            resourcesAddr,
            traitValueT3Ore,
            t3OreTokenId,
            resourcesOffered
        );
    }

    function setUpCosmeticsCampaign(
        address certificatesAddr,
        address cosmeticsAddr,
        bytes32 traitValue
    ) public returns (uint256) {
        OfferItem[] memory offer = new OfferItem[](1);
        offer[0] = OfferItem({
            itemType: ItemType.ERC721_WITH_CRITERIA,
            token: cosmeticsAddr,
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1
        });

        ConsiderationItem[] memory consideration = new ConsiderationItem[](1);
        consideration[0] = ConsiderationItem({
            itemType: ItemType.ERC1155_WITH_CRITERIA,
            token: certificatesAddr,
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1,
            recipient: payable(BURN_ADDRESS)
        });

        TraitRedemption[] memory traitRedemptions = new TraitRedemption[](1);
        traitRedemptions[0] = TraitRedemption({
            substandard: 4, // an indicator integer
            token: certificatesAddr,
            traitKey: traitKey,
            traitValue: traitValue, // new trait value
            substandardValue: traitValue // required previous value
        });

        // Create the second campaign for goldprint
        CampaignRequirements[] memory requirements = new CampaignRequirements[](
            1
        );
        requirements[0].offer = offer;
        requirements[0].consideration = consideration;
        requirements[0].traitRedemptions = traitRedemptions;
        CampaignParams memory params = CampaignParams({
            signer: address(0),
            startTime: campaignStartTime,
            endTime: campaignEndTime,
            maxCampaignRedemptions: maxCampaignRedemptions,
            manager: msg.sender
        });

        Campaign memory campaign = Campaign({
            params: params,
            requirements: requirements
        });

        uint256 campaignId = ERC721ShipyardRedeemableMintable(cosmeticsAddr)
            .createCampaign(campaign, "uri://");
        return campaignId;
    }

    function setUpCosmeticsCampaigns(
        address cosmeticsAddr,
        address certificatesAddr
    ) public {
        setUpCosmeticsCampaign(certificatesAddr, cosmeticsAddr, traitValueHat1);
        setUpCosmeticsCampaign(certificatesAddr, cosmeticsAddr, traitValueHat2);
        setUpCosmeticsCampaign(certificatesAddr, cosmeticsAddr, traitValueHat3);
        setUpCosmeticsCampaign(
            certificatesAddr,
            cosmeticsAddr,
            traitValueEyepiece1
        );
        setUpCosmeticsCampaign(
            certificatesAddr,
            cosmeticsAddr,
            traitValueEyepiece2
        );
        setUpCosmeticsCampaign(
            certificatesAddr,
            cosmeticsAddr,
            traitValueEyepiece3
        );
        setUpCosmeticsCampaign(
            certificatesAddr,
            cosmeticsAddr,
            traitValueCannon1
        );
        setUpCosmeticsCampaign(
            certificatesAddr,
            cosmeticsAddr,
            traitValueCannon2
        );
        setUpCosmeticsCampaign(
            certificatesAddr,
            cosmeticsAddr,
            traitValueCannon3
        );
    }

    function mintAndSetTraits(address certificatesAddr) public {
        // Test function for minting and setting traits
        // I used this set up some test certificates for chris
        ERC1155ShipyardRedeemableMintable certificates = ERC1155ShipyardRedeemableMintable(
                certificatesAddr
            );
        // for (uint i = 10; i < 60; i++) {
        //     certificates.mint(msg.sender, i, 1); // certificate
        // }

        // for (uint i = 10; i < 60; i++) {
        //     certificates.setTrait(i, traitKey, traitValueWraithGoldprint);
        // }

        for (uint i = 1; i < 5; i++) {
            uint tokenIdBase = 100000 + (i * 100);
            for (uint j = 1; j <= 19; j++) {
                uint tokenId = tokenIdBase + j;
                bytes32 traitValue = bytes32(j);

                certificates.mint(msg.sender, tokenId, 1); // certificate
                certificates.setTrait(tokenId, traitKey, traitValue);
            }
        }
    }

    function run() external {
        // Instructions for running:
        // Run anvil in another terminal
        // For the PK, I was using the first wallet from Anvil
        // Run export PK=
        // Run: export RPC_URL="http://127.0.0.1:8545"
        // Run: forge script script/CNC.s.sol --rpc-url ${RPC_URL} --private-key ${PK}  -vvvv

        vm.startBroadcast();

        // Deploy the contracts
        // ERC721ShipyardRedeemableMintableRentable lootboxes = new ERC721ShipyardRedeemableMintableRentable(
        //         "Captain & Company - Clockwork Lootbox",
        //         "CNC-CLBX"
        //     );

        // ERC1155ShipyardRedeemableMintable certificates = new ERC1155ShipyardRedeemableMintable(
        //         "Captain & Company - Certificates",
        //         "CNC-CERTS"
        //     );

        // TODO: update to the Resources contract.
        // ERC1155ShipyardRedeemableMintable resources = new ERC1155ShipyardRedeemableMintable(
        //         "Captain & Company - Resources",
        //         "CNC-RSRCS"
        //     );

        // ERC721ShipyardRedeemableMintableRentable ships = new ERC721ShipyardRedeemableMintableRentable(
        //         "Captain & Company - Ships",
        //         "CNC-SHIPS"
        //     );

        // ERC721ShipyardRedeemableMintable cosmetics = new ERC721ShipyardRedeemableMintable(
        //         "Cosmetics",
        //         "CNS-COSM"
        //     );

        // TestERC20 weth = new TestERC20(); // for testing locally

        // address lootboxesAddr = address(lootboxes);
        // address shipsAddr = address(ships);
        // address certificatesAddr = address(certificates);
        // address resourcesAddr = address(resources);
        // address cosmeticsAddr = address(cosmetics);
        // address wethAddr = address(weth);

        // Arbitrum Goerli addresses (v2 deployment)
        // address lootboxesAddr = 0x95A863f964534527f733e2fA1f4B09D7076A80ef;
        // address shipsAddr = 0xa38D0828B6a9432C6adfdA0557cD6378AfCeaE1B;
        // address certificatesAddr = 0x5e1a8F974642dE67a43587A469b143f39444223d;
        // address resourcesAddr = 0x6fdb1978218A3f31dAF107875Ae25a930A1A1EF1;
        // address cosmeticsAddr = 0x479750c63C3243375A52115C0987c4f78B48c398;
        // address wethAddr = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1; // https://arbiscan.io/address/0x82af49447d8a07e3bd95bd0d56f35241523fbab1

        // Sepolia addresses
        // address certificatesAddr = 0xDa2eBf447B5a3d7d3C1201BF185e9c031765425e;
        // address wethAddr = 0xD0dF82dE051244f04BfF3A8bB1f62E1cD39eED92; // Sepolia https://sepolia.etherscan.io/address/0xd0df82de051244f04bff3a8bb1f62e1cd39eed92

        // Used for on-chain, not locally
        // mintAndSetTraits(certificatesAddr);

        // setUpCertificatesCampaign(lootboxesAddr, certificatesAddr);

        // setUpShipCampaigns(
        //     shipsAddr,
        //     certificatesAddr,
        //     resourcesAddr,
        //     wethAddr
        // );
        // setUpResourcesCampaigns(resourcesAddr, certificatesAddr);
        // setUpCosmeticsCampaigns(cosmeticsAddr, certificatesAddr);

        // testLootboxRedeem(lootboxesAddr, certificatesAddr);

        // testWraithRedeems(
        //     address(ships),
        //     address(certificates),
        //     address(resources),
        //     address(weth)
        // );

        // testRentals(shipsAddr);
    }
}
