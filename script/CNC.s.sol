// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {Test} from "forge-std/Test.sol";
import {ItemType} from "seaport-types/src/lib/ConsiderationEnums.sol";
import {OfferItem, ConsiderationItem} from "seaport-types/src/lib/ConsiderationStructs.sol";
import {CampaignParams, CampaignRequirements, TraitRedemption} from "../src/lib/RedeemablesStructs.sol";
import {BURN_ADDRESS} from "../src/lib/RedeemablesConstants.sol";
import {ERC721RedemptionMintable} from "../src/extensions/ERC721RedemptionMintable.sol";
import {TestERC20} from "../test/utils/mocks/TestERC20.sol";

import {ERC721ShipyardRedeemableMintable} from "../src/extensions/ERC721ShipyardRedeemableMintable.sol";
import {ERC721RedemptionMintable} from "../src/extensions/ERC721RedemptionMintable.sol";
import {ERC1155ShipyardRedeemableMintable} from "../src/extensions/ERC1155ShipyardRedeemableMintable.sol";

contract DeployAndConfigure1155Receive is Script, Test {
    address CNC_TREASURY = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

    // 0x6365727454797065000000000000000000000000000000000000000000000000
    bytes32 traitKey = bytes32("certType");

    bytes32 traitValueWraithBlueprint = bytes32(uint256(1));
    bytes32 traitValueWraithGoldprint = bytes32(uint256(2));
    bytes32 traitValueClockworkBlueprint = bytes32(uint256(3));
    bytes32 traitValueClockworkGoldprint = bytes32(uint256(4));

    uint32 campaignStartTime = 0; //  seconds since epoch
    uint32 campaignEndTime = 2000000000; // seconds since epoch
    uint32 maxCampaignRedemptions = 1_000_000_000;

    function mintAndTestLootboxRedeem(
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

        lootboxes.setPreapprovedAddress(certificatesAddr);
        lootboxes.mint(msg.sender, tokenId);
        lootboxes.setApprovalForAll(certificatesAddr, true); // TODO: remove me

        uint256[] memory traitRedemptionTokenIds = new uint256[](0);
        bytes memory data = abi.encode(
            1, // campaignId,
            0,
            bytes32(0),
            traitRedemptionTokenIds,
            uint256(0),
            bytes("")
        );

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;

        certificates.redeem(tokenIds, msg.sender, data);
    }

    function mintAndTest(
        address shipsAddr,
        address certificatesAddr,
        address resourcesAddr,
        address wethAddr
    ) public {
        // This mints tokens to msg.sender and tests calling redeem
        // Right now, it redeems a blueprint and then a goldprint

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

        // Mint some tokens for the redeem ingredients
        certificates.mint(msg.sender, 1, 1); // certificate
        resources.mint(msg.sender, 1, 100); // ore
        resources.mint(msg.sender, 2, 100); // lumber
        weth.mint(msg.sender, 1200); // weth

        certificates.setApprovalForAll(address(ships), true);
        resources.setApprovalForAll(address(ships), true);
        weth.approve(address(ships), 99999999);

        // Set traits
        certificates.setTrait(1, traitKey, traitValueWraithBlueprint);

        // Verify pre-redeem state
        assertEq(certificates.balanceOf(msg.sender, 1), 1);
        assertEq(certificates.balanceOf(CNC_TREASURY, 1), 0);
        assertEq(resources.balanceOf(msg.sender, 1), 100);
        assertEq(resources.balanceOf(msg.sender, 2), 100);
        assertEq(weth.balanceOf(msg.sender), 1200);
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
        assertEq(weth.balanceOf(msg.sender), 700);
        assertEq(weth.balanceOf(CNC_TREASURY), 500);

        // These are requiring viaIR=true in found.toml for reasons I don't understand.
        assertEq(certificates.balanceOf(msg.sender, 1), 0);
        assertEq(certificates.balanceOf(CNC_TREASURY, 1), 0);
        assertEq(resources.balanceOf(msg.sender, 1), 0);
        assertEq(resources.balanceOf(msg.sender, 2), 0);
        assertEq(resources.balanceOf(CNC_TREASURY, 1), 100);
        assertEq(resources.balanceOf(CNC_TREASURY, 2), 100);

        // Mint tokens for the goldprint campaign
        certificates.mint(msg.sender, 7, 1); // certificate
        certificates.setTrait(7, traitKey, traitValueWraithGoldprint);
        assertEq(
            certificates.getTraitValue(7, traitKey),
            traitValueWraithGoldprint
        );

        uint256[] memory traitRedemptionTokenIds2 = new uint256[](1);
        traitRedemptionTokenIds2[0] = 7;
        bytes memory data2 = abi.encode(
            2, // campaing id. I think this isn't being picked up by redeem
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

    function doARedeem(address shipsAddr, uint256 tokenToRedeem) public {
        // This was a helper function for testing a redeem
        // on arb1 to already deployed contracts
        // This was specificaly used for a goldprint

        uint256[] memory traitRedemptionTokenIds = new uint256[](1);
        traitRedemptionTokenIds[0] = 1;

        bytes memory data = abi.encode(
            2,
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

        OfferItem[] memory offer = new OfferItem[](1);
        offer[0] = OfferItem({
            itemType: ItemType.ERC1155_WITH_CRITERIA,
            token: certificatesAddr,
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1 // TODO: should be 3
        });

        ConsiderationItem[] memory consideration = new ConsiderationItem[](1);
        consideration[0] = ConsiderationItem({
            itemType: ItemType.ERC721_WITH_CRITERIA,
            token: lootboxesAddr,
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1,
            recipient: payable(BURN_ADDRESS) // TODO: the burn is failing and it's transferring to the burn address
        });

        // Create the second campaign for goldprint
        CampaignRequirements[] memory requirements = new CampaignRequirements[](
            1
        );
        requirements[0].offer = offer;
        requirements[0].consideration = consideration;

        CampaignParams memory params = CampaignParams({
            requirements: requirements,
            signer: address(0),
            startTime: campaignStartTime,
            endTime: campaignEndTime,
            maxCampaignRedemptions: maxCampaignRedemptions,
            manager: msg.sender
        });

        uint campaignId = certificates.createCampaign(params, "uri://");

        assertEq(campaignId, 1);
        return campaignId;
    }

    function setUpBlueprintCampaign(
        address shipsAddr,
        address certificatesAddr,
        address resourcesAddr,
        address wethAddr
    ) public returns (uint256) {
        // Creates a Blueprint campaigns for the ships contract considers the certificate, ore, lumber, and weth.
        // The offer is a ship
        // DynamicTraits are also checked on the ship and must correspond to blueprint.

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

        consideration[3] = ConsiderationItem({
            itemType: ItemType.ERC20,
            token: wethAddr,
            identifierOrCriteria: 0,
            startAmount: 500,
            endAmount: 500,
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
            requirements: requirements,
            signer: address(0),
            startTime: campaignStartTime,
            endTime: campaignEndTime,
            maxCampaignRedemptions: maxCampaignRedemptions,
            manager: msg.sender
        });

        uint campaignId = ships.createCampaign(
            params,
            "ipfs://QmQjubc6guHReNW5Es5ZrgDtJRwXk2Aia7BkVoLJGaCRqP"
        );
        assertEq(campaignId, 1);
        return campaignId;
    }

    function setUpGoldprintCampaign(
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
            recipient: payable(BURN_ADDRESS) // TODO: the burn is failing and it's transferring to the burn address
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
            requirements: requirements,
            signer: address(0),
            startTime: campaignStartTime,
            endTime: campaignEndTime,
            maxCampaignRedemptions: maxCampaignRedemptions,
            manager: msg.sender
        });

        uint campaignId = ships.createCampaign(
            params,
            "ipfs://QmQjubc6guHReNW5Es5ZrgDtJRwXk2Aia7BkVoLJGaCRqP"
        );

        assertEq(campaignId, 2);
        return campaignId;
    }

    function mintAndSetTraits(address certificatesAddr) public {
        // Test function for minting and setting traits
        // I used this set up some test certificates for chris
        ERC1155ShipyardRedeemableMintable certificates = ERC1155ShipyardRedeemableMintable(
                certificatesAddr
            );
        for (uint i = 10; i < 60; i++) {
            certificates.mint(msg.sender, i, 1); // certificate
        }

        for (uint i = 10; i < 60; i++) {
            certificates.setTrait(i, traitKey, traitValueWraithGoldprint);
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
        ERC721ShipyardRedeemableMintable lootboxes = new ERC721ShipyardRedeemableMintable(
                "Clockwork Lootbox",
                "CLKWRK-LB"
            );

        ERC1155ShipyardRedeemableMintable certificates = new ERC1155ShipyardRedeemableMintable(
                "Certificates",
                "CERTS"
            );

        ERC1155ShipyardRedeemableMintable resources = new ERC1155ShipyardRedeemableMintable(
                "Resources",
                "RSRCS"
            );

        TestERC20 weth = new TestERC20();

        ERC721ShipyardRedeemableMintable ships = new ERC721ShipyardRedeemableMintable(
                "Ships",
                "SHIPS"
            );

        ERC721ShipyardRedeemableMintable cosmetics = new ERC721ShipyardRedeemableMintable(
                "Cosmetics",
                "COSM"
            );

        address lootboxesAddr = address(lootboxes);
        address shipsAddr = address(ships);
        address certificatesAddr = address(certificates);
        address resourcesAddr = address(resources);
        address wethAddr = address(weth);

        // Arbitrum Goerli addresses
        // address shipsAddr = 0x343f8F27f060E8C38acd759b103D7f1FE9f035Bc;
        // address certificatesAddr = 0x9AB21513bf9c107CE53B6326500A1567C642c794;
        // address resourcesAddr = 0x19E6949Ee9f371bD12d7B15A0Ce0C6f3d16D2f5A;
        // address wethAddr = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1; // https://arbiscan.io/address/0x82af49447d8a07e3bd95bd0d56f35241523fbab1

        // Used for on-chain, not locally
        // mintAndSetTraits(certificatesAddr);

        setUpCertificatesCampaign(lootboxesAddr, certificatesAddr);

        mintAndTestLootboxRedeem(lootboxesAddr, certificatesAddr);

        uint256 blueprintCampaignId = setUpBlueprintCampaign(
            shipsAddr,
            certificatesAddr,
            resourcesAddr,
            wethAddr
        );

        uint256 goldprintCampaignId = setUpGoldprintCampaign(
            shipsAddr,
            certificatesAddr,
            resourcesAddr,
            wethAddr
        );

        mintAndTest(
            address(ships),
            address(certificates),
            address(resources),
            address(weth)
        );

    }
}
