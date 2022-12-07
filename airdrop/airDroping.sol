New Deployment:

KC token(bep20token) depolying on bscscan testnet .

https://testnet.bscscan.com/address/0x6751435d6dC23b548EaCA12a7290c17354a42288#code

sendAirDrop using bep20 token interface .

https://testnet.bscscan.com/address/0xE3D7526F016Ce8D001d8be382a3309bc5879609D#code


sendEtherToMany address like AirDrop


// SPDX-License-Identifier:MIT
pragma solidity 0.8.13;

interface IBEP20{
    function transfer(address receiver, uint256 tokenAmount) external  returns(bool);
}

contract sendAirDrop{

    IBEP20 public token1;
    constructor(IBEP20 _token){
        token1 = _token;
    }
    address public admin = msg.sender;
    mapping(address=>uint256) private checkBalance;

    modifier onlyOwner{
    require(msg.sender == admin);
    _;
    
    }

    function chkbalance(address _user) private view returns(uint256){
        return checkBalance[_user];
    }

    function checkALL(address _user) public view returns(uint256,bool){
        if (chkbalance(_user) > 0){
            return (chkbalance(_user),true);
        }
        return (0,false);
    }

    function sendEther(address [] memory _user, uint256[] memory _amount) external payable onlyOwner {
        for(uint i; i < _user.length; i++){
         payable (_user[i]).transfer(_amount[i]);
        }
    
    }

}