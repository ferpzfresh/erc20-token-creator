pragma solidity ^0.4.20;

///////////////////////////////////////////////////////////////////////////
    //ERC20 TOKEN CREATOR CONTRACT
    //Repository @ https://github.com/theblockchainlottery/erc20-token-creator
///////////////////////////////////////////////////////////////////////////

contract TokenCreator {

    uint256 constant private MAX_UINT256 = 2**256 - 1;
    
    address public owner;
    uint private creationPrice;
    uint private tokensCreated;
    address[] public tokenContractAddresses;
    bool private isActive;
    
    struct Tokens {
        uint tokenSupply;
        uint8 tokenDecimals;
        string tokenSymbol;
        string tokenName;
        address tokenOwner;
        uint tokenID;
        address tokenAddress;
    }

    mapping (address => Tokens) private token_map;
    mapping (address => uint) private user_tokens;

//////////////////
    //EVENTS
//////////////////
    event ContractMsg(string message);
    event NewToken(string msg, string t_name, string msg2, address tokenContractAddress);
     
/////////////////
    //SETUP
/////////////////
    // when applied to a function it can only be called by the contract creator
    modifier onlyOwner { 
        require(msg.sender == owner);
        _;
    }

    //called on contract creation
    constructor() public {
        owner = msg.sender;
        //set token creation price
        creationPrice = 100000000000000000 wei;
        //set contract active
        isActive = true;
        //event
        emit ContractMsg("Initial token creator contract deployed successfully");//event
    }

/////////////////////////////////////////////////////
    //FUNCTIONS ONLY TO BE CALLED BY CONTRACT CREATOR//
/////////////////////////////////////////////////////
    //transfer contract eth to dev
    function sweepContract() public onlyOwner {
        require(contractBalance() > 0);
        owner.transfer(contractBalance());
    }
    
    //destroy contract
    function destroyContract(bool deleteContract) public onlyOwner {
        if (deleteContract) {
            selfdestruct(owner);            
        } else {
            revert();
        }
    }

    //change token creation price 
    function setPrice(uint newPrice) public onlyOwner {
        creationPrice = newPrice;
    }

///////////////////////////////////////
    //PUBLIC FUNCTIONS
///////////////////////////////////////
    //get token creation price
    function getPrice() public view returns (uint){
        return creationPrice;
    }

    //get balance of contract
    function contractBalance() public view returns(uint) {
        address contractAddress = this;
        return contractAddress.balance;
    }

    //return number of tokens created from this contract
    function allTokensCreated() public view returns(uint) {
        return tokensCreated;
    }
    
    //see own token details 
    function myLastToken() public view returns(string, string, uint, uint, address, uint, address) {
        return (
            token_map[msg.sender].tokenName, 
            token_map[msg.sender].tokenSymbol, 
            token_map[msg.sender].tokenSupply, 
            token_map[msg.sender].tokenDecimals, 
            token_map[msg.sender].tokenOwner, 
            token_map[msg.sender].tokenID, //tokens created by tokenOwner
            token_map[msg.sender].tokenAddress);
    }

///////////////////////////
    //MAIN
//////////////////////////
    //create new token
    function createToken(
        uint256 _initialAmount,
        string _tokenName, 
        uint8 _decimalUnits, 
        string _tokenSymbol, 
        uint _devPercentage
        ) public payable {
        require(msg.value >= creationPrice && _initialAmount < MAX_UINT256);
       //deploy new token contract
        address newTokenContract = new Token(_initialAmount, _tokenName, _decimalUnits, _tokenSymbol, _devPercentage, msg.sender, owner);
       //add to array
        tokenContractAddresses.push(newTokenContract);
         //map sender address and corresponding data into Token struct
        Tokens storage _token = token_map[msg.sender];
        _token.tokenSupply = _initialAmount; 
        _token.tokenName = _tokenName;
        _token.tokenSymbol = _tokenSymbol;
        _token.tokenDecimals = _decimalUnits;
        _token.tokenOwner = msg.sender;
        _token.tokenAddress = newTokenContract;
        _token.tokenID = user_tokens[msg.sender];
        user_tokens[msg.sender]++;
        //increment tokens created
        tokensCreated++;
        //event
        emit NewToken("Token Created - ", _tokenName, " - Contract Address = ", newTokenContract);
    }
}

///////////////////////////////////////////////////////////////////////////
    //ERC20 TOKEN CONTRACT
    //Implements EIP20 token standard: https://github.com/ethereum/EIPs/issues/20
///////////////////////////////////////////////////////////////////////////

import "./EIP20Interface.sol"; //import interface

contract Token is EIP20Interface {

    uint256 constant private MAX_UINT256 = 2**256 - 1;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    
    string public name;                   
    uint8 public decimals;
    string public symbol;
    uint private devDonation;
    uint private creatorTokens;
    
    constructor(
     uint256 _initialAmount,
     string _tokenName,
     uint8 _decimalUnits, 
     string _tokenSymbol, 
     uint devPercentage, 
     address creatorWallet, 
     address devWallet) 
     public {
        require(devPercentage >= 0 && devPercentage <= 100);
        if (devPercentage > 0) {
            devDonation = (_initialAmount / 100) * devPercentage; //calculate dev donation tokens
            creatorTokens = (_initialAmount - devDonation); //calculate creator tokens 
            balances[devWallet] = devDonation; //send dev tokens if specified
            emit Transfer(0x0, devWallet, devDonation);
        } else {
            creatorTokens = _initialAmount; //no dev donation - creator will receive all initial tokens
        }
        balances[creatorWallet] = creatorTokens; //send the creator tokens
        emit Transfer(0x0, creatorWallet, creatorTokens);
        totalSupply = _initialAmount;            //update total supply
        name = _tokenName;                       //set the name for display purposes
        decimals = _decimalUnits;                //amount of decimals for display purposes
        symbol = _tokenSymbol;                   //set the symbol for display purposes
        
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }   
}
