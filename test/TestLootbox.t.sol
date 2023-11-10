// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {ERC721ShipyardRedeemableMintable} from "../src/extensions/ERC721ShipyardRedeemableMintable.sol";
import {BaseRedeemablesTest} from "./utils/BaseRedeemablesTest.sol";

contract ERC7498_SimpleRedeem is BaseRedeemablesTest {
    ERC721ShipyardRedeemableMintable lootboxes;

    function setUp() public virtual override {
        super.setUp();

        lootboxes = new ERC721ShipyardRedeemableMintable(
            "Captain & Company - Clockwork Lootbox",
            "CNC-CLBX"
        );
    }

    function testRevert() public {
        // assertEq(1, 1);
        // https://book.getfoundry.sh/cheatcodes/expect-revert?highlight=expectRevert
        vm.expectRevert(bytes("NOT_AUTHORIZED"));
        revert("NOT_AUTHORIZED");
    }

    function testMint() public {
        lootboxes.mint(msg.sender, 1);
        lootboxes.mint(address(0xABCD), 3);

        assertEq(lootboxes.ownerOf(1), msg.sender);
        assertEq(lootboxes.ownerOf(3), address(0xABCD));
    }

    function testMintAndBurn() public {
        address addr1 = address(0xDCBA);
        address addr2 = address(0xABCD);

        lootboxes.mint(addr1, 1);

        vm.expectRevert();
        lootboxes.burn(100); // Revert because token does not exist

        vm.startPrank(addr2); // https://book.getfoundry.sh/cheatcodes/prank

        vm.expectRevert();
        lootboxes.mint(addr2, 2);

        vm.expectRevert();
        lootboxes.burn(1); // revert because not owner or approved

        vm.stopPrank();
    }
}
