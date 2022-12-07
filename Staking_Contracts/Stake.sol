// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
contract addUser{
    address[] public arrayaddr;
    mapping(address => bool) checkAddr;

    function stake() public returns(address[] memory) {
        require(checkAddr[msg.sender] != true);
        arrayaddr.push(msg.sender); 
        checkAddr[msg.sender] = true;
        return arrayaddr;
    }
    function unstake() public returns(address[] memory){
        
        require(checkAddr[msg.sender] == true);
        // address admin = msg.sender;
        for (uint i = 0; i <= arrayaddr.length; i++){
            if (msg.sender != arrayaddr[i]){
                continue;
            }
            else{
                arrayaddr[i] = arrayaddr[arrayaddr.length-1];
                arrayaddr.pop();
            }
            
        }
        // arrayaddr[index] = arrayaddr[arrayaddr.length-1];
        // checkAddr[index] = checkAddr[checkAddr.length-1];

        // arrayaddr.pop();
        // checkAddr.pop();
        
        return arrayaddr;
        }
        // require(msg.sender )
        
    }

    // function arrayDisplay() public view returns(address[] memory){
    //     return arrayaddr;
    // }