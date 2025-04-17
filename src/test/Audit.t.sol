// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "./NudgeCampaign.t.sol";

contract PoCTest is NudgeCampaignTest {

    function test_reentrancy() public {
        address campaignWithNativeRewardsAddress = factory.deployAndFundCampaign{value: 100 ether}(
            holdingPeriodInSeconds,
            address(toToken),
            NATIVE_TOKEN,
            REWARD_PPQ,
            campaignAdmin,
            0,
            alternativeWithdrawalAddress,
            100 ether,
            RANDOM_UUID
        );
        NudgeCampaign campaignWithNativeToken = NudgeCampaign(payable(campaignWithNativeRewardsAddress));

        uint256 toAmount = 100e18;
        // Simulate getting toTokens from end user
        vm.prank(swapCaller);
        toToken.faucet(toAmount);

        vm.prank(swapCaller);
        toToken.approve(campaignWithNativeRewardsAddress, toAmount);

        vm.prank(swapCaller);
        campaignWithNativeToken.handleReallocation(RANDOM_UUID, alice, address(toToken), toAmount, "");

        vm.warp(block.timestamp + holdingPeriodInSeconds + 1);

        uint256 balanceBefore = alice.balance;

        // Claim rewards
        vm.prank(alice);
        campaignWithNativeToken.claimRewards(pIDsWithOne);

        uint256 balanceAfter = alice.balance;
        (uint256 userRewards, ) = getUserRewardsAndFeesFromToAmount(campaignWithNativeToken, toAmount);
        assertEq(balanceAfter, balanceBefore + userRewards);
    }

    function invariant_test1() public {
        // rewardToken.balanceOf(campaign) >= pendingRewards + accumulatedFees
    }

    function invariant_test2() public {
        // p.rewardAmount <= rewardToken.balanceOf(campaign) - (pendingRewards - p.rewardAmount) - accumulatedFees
    }
}
 