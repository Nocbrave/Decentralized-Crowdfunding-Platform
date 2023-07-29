// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CrowdfundingPlatform {
    struct Campaign {
        uint256 id;
        address creator;
        string title;
        string description;
        uint256 goalAmount;
        uint256 endTime;
        bool isGoalReached;
        bool isClosed;
        uint256 totalContributions;
        mapping(address => uint256) contributions;
    }

    uint256 public numCampaigns;
    mapping(uint256 => Campaign) public campaigns;

    event CampaignCreated(uint256 campaignId, address creator, string title, uint256 goalAmount, uint256 endTime);
    event ContributionMade(uint256 campaignId, address contributor, uint256 amount);
    event GoalReached(uint256 campaignId, uint256 totalContributions);
    event CampaignClosed(uint256 campaignId, uint256 totalContributions);

    modifier onlyCampaignCreator(uint256 _campaignId) {
        require(msg.sender == campaigns[_campaignId].creator, "You are not the creator of this campaign");
        _;
    }

    modifier campaignOpen(uint256 _campaignId) {
        require(!campaigns[_campaignId].isClosed, "Campaign is closed");
        require(block.timestamp < campaigns[_campaignId].endTime, "Campaign has ended");
        _;
    }

    modifier campaignClosed(uint256 _campaignId) {
        require(campaigns[_campaignId].isClosed, "Campaign is not closed");
        _;
    }

    function createCampaign(
        string memory _title,
        string memory _description,
        uint256 _goalAmount,
        uint256 _durationDays
    ) public {
        require(_goalAmount > 0, "Goal amount must be greater than zero");
        require(_durationDays > 0, "Campaign duration must be greater than zero");

        numCampaigns++;
        uint256 campaignEndTime = block.timestamp + (_durationDays * 1 days);

        campaigns[numCampaigns] = Campaign({
            id: numCampaigns,
            creator: msg.sender,
            title: _title,
            description: _description,
            goalAmount: _goalAmount,
            endTime: campaignEndTime,
            isGoalReached: false,
            isClosed: false,
            totalContributions: 0
        });

        emit CampaignCreated(numCampaigns, msg.sender, _title, _goalAmount, campaignEndTime);
    }

    function contribute(uint256 _campaignId) public payable campaignOpen(_campaignId) {
        require(msg.value > 0, "Contribution amount must be greater than zero");
        Campaign storage campaign = campaigns[_campaignId];
        campaign.contributions[msg.sender] += msg.value;
        campaign.totalContributions += msg.value;

        emit ContributionMade(_campaignId, msg.sender, msg.value);

        if (campaign.totalContributions >= campaign.goalAmount) {
            campaign.isGoalReached = true;
            emit GoalReached(_campaignId, campaign.totalContributions);
        }
    }

    function releaseFunds(uint256 _campaignId) public campaignClosed(_campaignId) onlyCampaignCreator(_campaignId) {
        Campaign storage campaign = campaigns[_campaignId];
        require(campaign.isGoalReached, "Goal amount not reached");

        uint256 amountToTransfer = campaign.totalContributions;
        campaign.totalContributions = 0;
        campaign.isClosed = true;

        (bool success, ) = campaign.creator.call{value: amountToTransfer}("");
        require(success, "Transfer failed");

        emit CampaignClosed(_campaignId, amountToTransfer);
    }

    function getCampaignDetails(uint256 _campaignId)
        public
        view
        returns (
            address,
            string memory,
            string memory,
            uint256,
            uint256,
            bool,
            bool,
            uint256
        )
    {
        Campaign storage campaign = campaigns[_campaignId];
        return (
            campaign.creator,
            campaign.title,
            campaign.description,
            campaign.goalAmount,
            campaign.endTime,
            campaign.isGoalReached,
            campaign.isClosed,
            campaign.totalContributions
        );
    }
}

