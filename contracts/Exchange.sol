pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol";
import "openzeppelin-solidity/contracts/ownership/Claimable.sol";


contract Exchange is Claimable {

    struct Request {
        uint256 amount;
        address requesterAddress;
        address fromToken;
        address toToken;
        bool accepted;
    }

    Request[] public allExchangesRequests;
    address[] public allPermittedTokensAddresses;

    mapping(address => bool) public permittedExternalAddresses;
    mapping(address => bool) public permittedTokensAddresses;
    mapping(address => uint256) public tokenAddressToIndex;
    mapping(address => uint256[]) public tokenToExchangeRequestId;

    modifier requireExchangeIdExisting(uint256 _exchangeId) {
        require(
            _exchangeId < allExchangesRequests.length,
            "ACCESS DENIED"
        );
        _;
    }
    modifier onlyPermittedExternalAddresses() {
        require(
            permittedExternalAddresses[msg.sender] == true,
            "ACCESS DENIED"
        );
        _;
    }

    modifier onlyPermittedToken(address _tokenAddress) {
        require(
            permittedTokensAddresses[_tokenAddress] == true,
            "ACCESS DENIED"
        );
        _;
    }

    modifier requireAllowance(
        StandardToken _tokenAddress,
        address _tokenHolder,
        uint256 _expectedBalance
    ) {
        require(
            getTokenAllowance(
                _tokenAddress,
                _tokenHolder
            ) >= _expectedBalance,
            "ACCESS DENIED"
        );
        _;
    }

    event NewTokenAdded(address tokenAddress);

    event TokenRemoved(address tokenAddress);

    event ExchangeRequestCreated(
        uint256 _exchangeId,
        uint256 tokensAmount,
        address requesterAddress,
        address indexed fromToken,
        address indexed toToken
    );

    event TokensExchanged(
        uint256 _exchangeId,
        uint256 tokensAmount,
        address indexed fromToken,
        address indexed toToken
    );

    constructor(address[] _tokensForExchange)
        public
    {
        for (uint256 i = 0; i < _tokensForExchange.length; i++) {
            require(
                _tokensForExchange[i] != address(0),
                "INVALID ADDRESS"
            );
            permittedTokensAddresses[_tokensForExchange[i]] = true;
            tokenAddressToIndex[_tokensForExchange[i]] = i;
            allPermittedTokensAddresses.push(_tokensForExchange[i]);
        }
        permittedExternalAddresses[msg.sender] = true;
    }

    function createExchangeRequest(
        address _fromToken,
        address _toToken,
        uint256 _tokensAmount
    )
        public
        onlyPermittedToken(_fromToken)
        onlyPermittedToken(_toToken)
        requireAllowance(
            StandardToken(_fromToken),
            msg.sender,
            _tokensAmount
        )
    {
        require(
            _fromToken != _toToken,
            "INVALID ADDRESS"
        );
        tokenToExchangeRequestId[_fromToken].push(
            allExchangesRequests.length
        );

        emit ExchangeRequestCreated(
            allExchangesRequests.length,
            _tokensAmount,
            msg.sender,
            _fromToken,
            _toToken
        );

        allExchangesRequests.push(
            Request(
                _tokensAmount,
                msg.sender,
                _fromToken,
                _toToken,
                false
            )
        );
    }

    function externalExchange(
        uint256 _exchangeId,
        address _fromToken,
        address _toToken,
        address _exchangerAddress
    )
    public
    onlyPermittedExternalAddresses
    requireExchangeIdExisting(_exchangeId)
    {
        internalExchange(
            _exchangeId,
            _fromToken,
            _toToken,
            _exchangerAddress
        );
    }

    function setPermissionForAddress(
        address _address,
        bool _permission
    )
        public
        onlyOwner
    {
        require(_address != address(0), "ZERO ADDRESS");
        permittedExternalAddresses[_address] = _permission;
    }

    function addExchangeTokenAddress(
        StandardToken _address
    )
        public
        onlyOwner
    {
        require(_address != address(0), "ZERO ADDRESS");
        permittedTokensAddresses[_address] = true;
        tokenAddressToIndex[_address] = allPermittedTokensAddresses.length;
        allPermittedTokensAddresses.push(_address);
        emit NewTokenAdded(_address);
    }

    function removeTokenFromExchange(
        StandardToken _address
    )
        public
        onlyOwner
    {
        require(
            permittedTokensAddresses[_address] = true,
            "NOT PERMITTED"
        );
        permittedTokensAddresses[_address] = false;
        delete allPermittedTokensAddresses[tokenAddressToIndex[_address]];
        emit TokenRemoved(_address);
    }

    function exchangeTokens(
        uint256 _exchangeId
    )
        public
        requireExchangeIdExisting(_exchangeId)
    {
        Request memory request = allExchangesRequests[
            _exchangeId
        ];
        internalExchange(
            _exchangeId,
            request.toToken,
            request.fromToken,
            msg.sender
        );
    }

    function getSuitableRequestId(
        address _fromToken,
        address _toToken,
        uint256 _amount
    )
        public
        view
        onlyPermittedToken(_fromToken)
        onlyPermittedToken(_toToken)
        returns(uint256)
    {
        for (
            uint i = 0;
            i < tokenToExchangeRequestId[_toToken].length;
            i++
        ) {
            Request memory request = allExchangesRequests[
                tokenToExchangeRequestId[_toToken][i]
            ];
            if (
                request.accepted == true
                || _fromToken != request.toToken
                || _amount != request.amount
            ) {
                continue;
            }
            return tokenToExchangeRequestId[_toToken][i];
        }
        require(false, "ID NOT FOUND");
    }

    function internalExchange(
        uint256 _exchangeId,
        address _fromToken,
        address _toToken,
        address exchangerAddress
    )
        internal
        onlyPermittedToken(_fromToken)
        onlyPermittedToken(_toToken)
        requireExchangeIdExisting(_exchangeId)
    {
        Request storage request = allExchangesRequests[
            _exchangeId
        ];
        require(
            request.accepted == false
            && _fromToken == request.toToken,
            "NOT ALLOWED"
        );
        require(
            getTokenAllowance(
                StandardToken(_toToken),
                request.requesterAddress
            ) >= request.amount,
            "BALANCE IS NOT ALLOWED"
        );
        require(
            getTokenAllowance(
                StandardToken(_fromToken),
                exchangerAddress
            ) >= request.amount,
            "BALANCE IS NOT ALLOWED"
        );
        request.accepted = true;

        StandardToken(_toToken).transferFrom(
            request.requesterAddress,
            exchangerAddress,
            request.amount
        );

        StandardToken(_fromToken).transferFrom(
            exchangerAddress,
            request.requesterAddress,
            request.amount
        );
        emit TokensExchanged(
            _exchangeId,
            request.amount,
            _fromToken,
            _toToken
        );
    }

    function getTokenAllowance(
        StandardToken _tokenAddress,
        address _tokenHolder
    )
        internal
        view
        returns (uint256)
    {
       return StandardToken(_tokenAddress).allowance(
            _tokenHolder,
            address(this)
        );
    }
}
