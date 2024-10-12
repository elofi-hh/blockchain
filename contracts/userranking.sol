// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract UserRanking {
   
    mapping(string => uint8) public rankings;
    
    event RankingUpdated(string userId, uint8 rank);
   
    function setRanking(string memory userId, uint8 rank) public {
        rankings[userId] = rank;
        emit RankingUpdated(userId, rank);
    }

    function getRanking(string memory userId) public view returns (uint8) {
        return rankings[userId];
    }

    function increment(string memory userId, uint8 count) public {
        rankings[userId] += count; 
        uint8 newRank = rankings[userId]; 
        emit RankingUpdated(userId, newRank); 
    }
    function decrement(string memory userId, uint8 count) public {
        rankings[userId] -= count;
        uint8 newRank = rankings[userId];
        emit RankingUpdated(userId, newRank);
    }
    function updateRanking(string memory userId, uint8 networkEloRating, uint8 networkStrictnessRating, bool isAbuser) public {
        if (isAbuser) {
            rankings[userId] -= networkStrictnessRating;
        } else {
            rankings[userId] += networkEloRating;
        }

        if (rankings[userId] < 0) {
            rankings[userId] = 0;
        } else if (rankings[userId] > 100) {
            rankings[userId] = 100;
        }

        emit RankingUpdated(userId, rankings[userId]);
    }
        
}
