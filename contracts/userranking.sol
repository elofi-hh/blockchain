// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "abdk-libraries-solidity/ABDKMath64x64.sol";

contract UserRanking {

    mapping(string => uint16) public rankings;

    event RankingUpdated(string userId, uint16 rank);
    event KFactorUpdated(uint16 newKFactor);

    uint16 public K_FACTOR;

    constructor(uint16 initialKFactor) {
        K_FACTOR = initialKFactor;
    }

    function setKFactor(uint16 newKFactor) public {
        K_FACTOR = newKFactor;
        emit KFactorUpdated(newKFactor);
    }

    function setRanking(string memory userId, uint16 rank) public {
        rankings[userId] = rank;
        emit RankingUpdated(userId, rank);
    }

    function getRanking(string memory userId) public view returns (uint16) {
        return rankings[userId];
    }

    function calculateExpectedScore(int16 eloDiff) internal pure returns (int128) {
        int128 eloDiffFixed = ABDKMath64x64.fromInt(eloDiff);
        int128 ln10 = ABDKMath64x64.ln(ABDKMath64x64.fromUInt(10));
        int128 exponent = ABDKMath64x64.neg(
            ABDKMath64x64.div(
                ABDKMath64x64.mul(eloDiffFixed, ln10),
                ABDKMath64x64.fromInt(400)
            )
        );
        int128 expValue = ABDKMath64x64.exp(exponent);
        int128 expectedScore = ABDKMath64x64.div(
            ABDKMath64x64.fromInt(1),
            ABDKMath64x64.add(ABDKMath64x64.fromInt(1), expValue)
        );
        return expectedScore;
    }

    function updateRanking(
        string memory userId,
        uint16 networkEloRating,
        bool isAbuser
    ) public {
        if (rankings[userId] == 0) {
            rankings[userId] = 1000;
            uint16 rank = 1000;
            emit RankingUpdated(userId, rank);
        }
        uint16 userElo = rankings[userId];
        require(userElo <= 1000, "Invalid user Elo");

        int16 eloDiff = int16(userElo) - int16(networkEloRating);
        int128 expectedScore = calculateExpectedScore(eloDiff);

        int128 actualScore = isAbuser ? ABDKMath64x64.fromInt(0) : ABDKMath64x64.fromInt(1);

        int16 eloAdjustment = int16(
            ABDKMath64x64.toInt(
                ABDKMath64x64.mul(
                    ABDKMath64x64.fromUInt(K_FACTOR),
                    ABDKMath64x64.sub(actualScore, expectedScore)
                )
            )
        );

        int16 newElo = int16(userElo) + eloAdjustment;
        if (newElo > 1000) {
            newElo = 1000;
        } else if (newElo < 0) {
            newElo = 0;
        }

        rankings[userId] = uint16(newElo);
        emit RankingUpdated(userId, uint16(newElo));
    }
}
