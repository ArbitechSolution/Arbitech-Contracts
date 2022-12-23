// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

  /*
    * swapExactTokensForToken
    * Accepting both Tokens
    * Adding liquidity in Token against BUSD
    * Selling 20% from liquidity transection
  */

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function _approve(address owner, address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() 
    {   _status = _NOT_ENTERED;     }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _transferOwnership(_msgSender());
    }
    modifier onlyOwner() {
        _checkOwner();
        _;
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}


contract FCCBuyRouter is Ownable, ReentrancyGuard{

    using SafeMath for uint256;
    IERC20 public FCC;
    IERC20 public BUSD;

    IPancakeRouter01 public Router;

    uint256 public FCCToken;
    uint256 public BUSDToken;
    uint256 public PoolBUSDamount;
    uint256 public PoolPercentage = 50;
    uint256 public SWAPTokenPercentage = 20;
    uint256 public count;
    uint256 public SwapandLiquifyCount = 4;
    address public LpReceiver;
    address public BUSDReceiver;
    uint256 HalfToken;
    uint256 ContractBalance;
    uint256 public returnToken;

    constructor()
    {
       FCC = IERC20(0xbCa9f2D428e5e6eeFeDD8d48a70d8000c2a394a2);
       BUSD = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
       Router = IPancakeRouter01(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F);
       LpReceiver = 0x187C23f636808D81B347Ee77653F7E1f68C503Ce;
       BUSDReceiver = 0xE37cC19C8f69d856D273A6749738d414424C382E;
    }

    function FCCbuyRouter(uint256 _FCCtokens, uint256 _BUSDamount)
    public 
    nonReentrant
    {
        require(msg.sender == tx.origin," External Error ");
        require(FCC.transferFrom(_msgSender(),address(this),_FCCtokens)," Approve FCC First ");
        require(BUSD.transferFrom(_msgSender(),address(this),_BUSDamount)," Approve BUSD First ");
        require(_BUSDamount > 0 && _FCCtokens > 0 ,"Token amount must be greater than zero");
        PoolBUSDamount += (_BUSDamount.mul(PoolPercentage)).div(100);
        count++;
        bool pool;
        if(count == SwapandLiquifyCount){

        uint256 half = PoolBUSDamount/2;
        BUSD.approve(address(Router), half);
        uint256[] memory returnValues = swapExactTokensForToken(half, address(FCC));
        returnToken = Percentage(returnValues[1]);
        FCC.approve(address(Router), returnValues[1]);
        BUSD.approve(address(Router), half);
        addLiquiditys(returnValues[1], half);
        
        FCC.approve(address(Router), returnToken);
        swapTokensForToken(returnToken);
        pool = true;
        }
        if(pool) {
            count = 0;
            PoolBUSDamount = 0;
        }
    }

    function Percentage(uint256 _swapToken) internal view returns(uint256)
    {
        uint256 swapToken;
        swapToken = (_swapToken.mul(SWAPTokenPercentage)).div(100);
        return swapToken;
    }

    function swapExactTokensForToken(uint256 value, address token) private 
    returns (uint[] memory amounts)  
    {
        address[] memory path = new address[](2);
        path[0] = address(BUSD);
        path[1] = token;
        return Router.swapExactTokensForTokens(
        value,
        0, 
        path,
        address(this), 
        block.timestamp
        );
    }

    function addLiquiditys(uint256 _amount,uint256 _half) private 
    {
        Router.addLiquidity(
            address(FCC),
            address(BUSD),
            _amount,
            _half,
            0,
            0,
            LpReceiver,
            block.timestamp
        );
    }

    function swapTokensForToken(uint256 _tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(FCC);
        path[1] = address(BUSD);
        Router.swapExactTokensForTokens(
            _tokenAmount,
            0,
            path,
            BUSDReceiver,
            block.timestamp
        );
    }


    function UpdateLpReceiver(address LpReceiver_)
    public
    onlyOwner
    {     LpReceiver = LpReceiver_;        }

    function UpdateBUSDReceiver(address BUSDReceiver_)
    public
    onlyOwner
    {    BUSDReceiver = BUSDReceiver_;         }

    function UpdateROUTER(IPancakeRouter01 _Router)
    public
    onlyOwner
    {      Router = _Router;        }

    function UpdatePercentage(uint256 _SWAPTokenPercentage)
    public
    onlyOwner
    {      SWAPTokenPercentage = _SWAPTokenPercentage;      }

    function UpdateCondition(uint256 SwapandLiquifyCount_)
    public
    onlyOwner
    {      SwapandLiquifyCount = SwapandLiquifyCount_;      }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    function withdrawableFCC()
    private
    view returns(uint256 amount)
    {
        amount = FCC.balanceOf(address(this));
        return amount = amount.sub((amount.mul(30)).div(100));
    }

    function withdrawFCC()
    public
    onlyOwner
    {   FCC.transfer(owner(),withdrawableFCC());   }

    function Emergencywithdraw()
    public
    onlyOwner
    {   FCC.transfer(owner(),(FCC.balanceOf(address(this))));   }


    function withdrawableBUSD()
    private
    view returns(uint256 amount)
    {
        amount = BUSD.balanceOf(address(this));
        return amount = amount - PoolBUSDamount; 
    }

    function withdrawBUSD()
    public
    onlyOwner
    {   BUSD.transfer(owner(),withdrawableBUSD());   }

    function EmergencywithdrawBUSD()
    public
    onlyOwner
    {   BUSD.transfer(owner(),(BUSD.balanceOf(address(this))));   }

}