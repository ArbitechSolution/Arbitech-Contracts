// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

contract stakingAndUnStaking{

    address[] public stakeHolders;
    uint256[] public value;

    function Staking(address _stakeHolders, uint256 _value) public returns(address[] memory, uint256[] memory) {
      stakeHolders.push(_stakeHolders);
      value.push(_value);  

      return(stakeHolders, value);
    }

    function getVal(uint i) public view returns(uint){
        return value[i];
    }

    function Remove(uint index) public returns(address[] memory, uint256[] memory){
        // for (uint i = index; i< stakeHolders.length-1; i++){
        //     stakeHolders[i] = stakeHolders[i+1];
        // }

        // replace the indexes
        stakeHolders[index] = stakeHolders[stakeHolders.length-1];
        value[index] = value[value.length-1];

        /*          Popping Values    */
        stakeHolders.pop();
        value.pop();
        
        return (stakeHolders, value);

    }
}