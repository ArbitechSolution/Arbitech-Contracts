// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";

contract DAOGovernor is Governor, GovernorCountingSimple, GovernorVotes {

    constructor(IVotes _token) Governor("DAOGovernor") GovernorVotes(_token) {}

    struct propsalsCore{
        address[] targets_;
        uint256[] values_;
        bytes[] calldatas_;
        string description_;
    }

    mapping(uint256 => propsalsCore) private proposals_;

    function votingDelay() public pure override returns (uint256) {
        return 1; // 1 block
    }

    function votingPeriod() public pure override returns (uint256) {
        // return 50400; // 1 week
        return 30; // 1 week
    }

    function quorum(uint256 blockNumber) public pure override returns (uint256) {
        return 4e18;
    }

    function proposalThreshold() public pure override returns (uint256) {
        return 5e18;
    }

    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public virtual override returns(uint256) 
    {

        uint256 proposalID = super.propose(targets, values, calldatas, description);
        propsalsCore storage proposals = proposals_[proposalID];
        proposals.targets_ = targets;
        proposals.values_ = values;
        proposals.calldatas_ = calldatas;
        proposals.description_ = description;

        return proposalID;
    }

    function cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    )public returns(uint256){
        uint256 proposalID = super._cancel(targets, values, calldatas, descriptionHash);
        return proposalID;
    }

    function getProposalDetails(uint256 _proposalID) public view 
    returns(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory data,
        string memory description
    )
    {
        propsalsCore storage proposals = proposals_[_proposalID];
        targets = proposals.targets_;
        values = proposals.values_;
        data = proposals.calldatas_;
        description = proposals.description_;
    }

    function getDescription(uint256 _proposalID) public view returns(string memory description){
        propsalsCore storage proposals = proposals_[_proposalID];
        description = proposals.description_;

    }

    function getDescriptionHashs(string memory description) public pure returns(bytes32 hash){
       hash = keccak256(bytes(description));
    }
}



// ["0xf6f2Bd97D33EAB1cFa78028d4e518823B9158430","0x2BF1c0c3EE486e7817358B0ca44995EA505209ec","0xE4E7DC0dD4f81A2A5560E911F749D6038284a72E","0x4A69C39f87C4Bb34dddc66EE8a161c4c31b9A8C5","0x2492Ec6991786b1b9Ce18064835A55275E4671F0","0xdcC18d2Fe2126c20946e7dC0B1d821e874FEd40d","0x25dDDF980aC927D545d49F1a9dE7693D874659B1","0x759a6ba67719A1c272B5e143FF1e36b89207Fd86"]

// ["1000000000000000000","1000000000000000000","1000000000000000000","1000000000000000000","1000000000000000000","1000000000000000000","1000000000000000000","1000000000000000000"]

// ["0x000000000000000000000000f6f2bd97d33eab1cfa78028d4e518823b9158430","0x0000000000000000000000002bf1c0c3ee486e7817358b0ca44995ea505209ec","0x000000000000000000000000e4e7dc0dd4f81a2a5560e911f749d6038284a72e","0x0000000000000000000000004a69c39f87c4bb34dddc66ee8a161c4c31b9a8c5","0x0000000000000000000000002492ec6991786b1b9ce18064835a55275e4671f0","0x000000000000000000000000dcc18d2fe2126c20946e7dc0b1d821e874fed40d","0x00000000000000000000000025dddf980ac927d545d49f1a9de7693d874659b1","0x000000000000000000000000759a6ba67719a1c272b5e143ff1e36b89207fd86"]

