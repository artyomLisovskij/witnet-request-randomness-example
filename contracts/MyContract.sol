// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "witnet-solidity-bridge/contracts/UsingWitnet.sol";
import "witnet-solidity-bridge/contracts/requests/WitnetRequest.sol";
import "@openzeppelin/contracts/access/Ownable.sol";  
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

contract MyContract is Ownable, UsingWitnet {
    event RandomnessQueried(uint256 _internalId, uint256 _witnetId);
    event Randomized(uint256 _status, uint256 _internalId, uint256 _result);
    using ERC165Checker for address;
    /// @dev Low-level Witnet Data Request composed on construction.
    WitnetRequest public immutable witnetRandomnessRequest;
    WitnetRequestBoard private immutable __witnet;
    /// @dev Randomness value eventually fetched from the Witnet oracle.
    bytes32 public witnetRandomness;
    bytes32 internal immutable __witnetRandomnessRadHash;
    bytes32 internal __witnetRandomnessSlaHash;
    mapping(uint256 => uint256) public internalQueryToWitnetQueryId;
    mapping(uint256 => uint256) public queriesResults;
    uint256 public internalQueriesCounter;

    constructor(WitnetRequestBoard _witnet)
        UsingWitnet(_witnet) 
        Ownable(msg.sender)
    {
        require(
            address(_witnet) == address(0)
                || address(_witnet).supportsInterface(type(WitnetRequestBoard).interfaceId),
            "WitnetRandomnessProxiable: uncompliant request board"
        );
        __witnet = _witnet;
        WitnetBytecodes _registry = witnet().registry();
        WitnetRequestFactory _factory = witnet().factory();
        {
            // Build own Witnet Randomness Request:
            bytes32[] memory _retrievals = new bytes32[](1);
            _retrievals[0] = _registry.verifyRadonRetrieval(
                WitnetV2.DataRequestMethods.Rng,
                "", // no schema
                "", // no authority
                "", // no path
                "", // no query
                "", // no body
                new string[2][](0), // no headers
                hex"80" // no retrieval script
            );
            WitnetV2.RadonFilter[] memory _filters;
            bytes32 _aggregator = _registry.verifyRadonReducer(WitnetV2.RadonReducer({
                opcode: WitnetV2.RadonReducerOpcodes.Mode,
                filters: _filters, // no filters
                script: hex"" // no aggregation script
            }));
            bytes32 _tally = _registry.verifyRadonReducer(WitnetV2.RadonReducer({
                opcode: WitnetV2.RadonReducerOpcodes.ConcatenateAndHash,
                filters: _filters, // no filters
                script: hex"" // no aggregation script
            }));
            WitnetRequestTemplate _template = WitnetRequestTemplate(_factory.buildRequestTemplate(
                _retrievals,
                _aggregator,
                _tally,
                0
            ));
            witnetRandomnessRequest = WitnetRequest(_template.buildRequest(new string[][](_retrievals.length)));
            __witnetRandomnessRadHash = witnetRandomnessRequest.radHash();
        }
        settleWitnetRandomnessSLA(WitnetV2.RadonSLA({
            numWitnesses: 5,
            minConsensusPercentage: 51,
            witnessReward: 10 ** 8,
            witnessCollateral: 10 ** 9,
            minerCommitRevealFee: 10 ** 7
        }));
    }

    function witnet()
        virtual override (UsingWitnet)
        public view returns (WitnetRequestBoard)
    {
        return UsingWitnet.witnet();
    }

    function checkQueryByInternalId(uint256 _internalId) 
        public view returns (bool)
    {
        uint _queryId = internalQueryToWitnetQueryId[_internalId];
        return _witnetCheckResultAvailability(_queryId);
    }
    
    function settleWitnetRandomnessSLA(WitnetV2.RadonSLA memory _radonSLA)
        virtual
        public
        onlyOwner
        returns (bytes32 _radonSlaHash)
    {
        _radonSlaHash = witnet().registry().verifyRadonSLA(_radonSLA);
        __witnetRandomnessSlaHash = _radonSlaHash;
    }

    function askForRandomness()
        external payable
        onlyOwner
    {
        uint256 _witnetReward;
        uint256 _witnetQueryId;
        (_witnetQueryId, _witnetReward) = _witnetPostRequest(
            __witnetRandomnessRadHash,
            __witnetRandomnessSlaHash  
        );

        // transfer back unused funds
        if (msg.value > _witnetReward) {
            payable(msg.sender).transfer(msg.value - _witnetReward);
        }
        internalQueryToWitnetQueryId[internalQueriesCounter] = _witnetQueryId;
        emit RandomnessQueried(internalQueriesCounter, _witnetQueryId);
        internalQueriesCounter++;
    }

    function getWitnetQueryResult(uint256 internalQueryId)
        external
    {
        uint _queryId = internalQueryToWitnetQueryId[internalQueryId];
        require(_witnetCheckResultAvailability(_queryId), "not yet reported");
        Witnet.Result memory _result = witnet().readResponseResult(_queryId);
        if (_result.success) {
            queriesResults[internalQueryId] = uint256(witnet().asBytes32(_result));
            emit Randomized(1, internalQueryId, queriesResults[internalQueryId] );
        } else {
            emit Randomized(0, internalQueryId, 0);
        }
    }

}