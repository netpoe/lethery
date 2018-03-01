pragma solidity ^0.4.19;

import 'zeppelin-solidity/contracts/math/SafeMath.sol';

contract Lethery {

    using SafeMath for uint;

    address public admin; // addres of Lethery admin
    address public feeAddress; // the address of the fees holder
    uint public volume; // total amount of ETH accumulated from all games
    uint public fee; // (5 / 100) / Game volume
    uint public lastFeeVolume; // last fee in ETH paid to feeAddress
    uint public currentGame; // sha3 hash of current game
    uint public winningNumbersLength; // allowed number of winning numbers
    uint public gamesLength; // the length in solidity time values
    uint public gamePrice; // the price of playing the games
    
    struct Game {
        uint id; // sha3 hash of this game marked by its start date and end date 
        mapping (uint => address[]) players; // chosen 6 to 12 digits number to addresses of players who chose that number
        uint playersCount;
        uint beginsAt; // UNIX timestamp
        uint endsAt; // UNIT timestamp
        uint[] winningNumbers; // the numbers that account for this game
        uint price; // the price for this game in ETH
        uint volume; // the ETH volume for this game
        bool isRedeemed; // whether the game has been redeemed or not
        bool isCurrent;
    }
    
    mapping (uint => Game) public games;
    
    modifier noCurrentGame {
        Game storage game = games[currentGame];
        
        require(!game.isCurrent);
        
        _;
    }
    
    modifier gameIsOver {
        require(currentGame != 0);
        
        Game storage game = games[currentGame];
        
        require(now > game.endsAt);
        
        _;
    }
    
    modifier gameIsNotRedeemed {
        Game storage game = games[currentGame];
        
        require(!game.isRedeemed);
        
        _;
    }
    
    modifier isAdmin {
        require(msg.sender == admin);
        
        _;
    }
    
    modifier isValidNumber (uint number) {
        require(number > 99999); // number must have +6 digits
        require(number <= 999999999999); // number must have up to 12 digits
        
        _;
    }
    
    function Lethery (address _feeAddress, uint _gamePrice, uint _fee) public {
        admin = msg.sender;
        feeAddress = _feeAddress;
        gamePrice = _gamePrice;
        fee = _fee;
        winningNumbersLength = 3;
        gamesLength = 30;
        currentGame = 0;
    }
    
    function createGame () public isAdmin noCurrentGame {
        uint _beginsAt = now;
        uint _endsAt = _beginsAt + 10 seconds;
        
        ++currentGame;
        
        games[currentGame].id = currentGame;
        games[currentGame].beginsAt = _beginsAt;
        games[currentGame].endsAt = _endsAt;
        games[currentGame].price = gamePrice;
        games[currentGame].isRedeemed = false;
        games[currentGame].volume = 0;
        games[currentGame].isCurrent = true;
        games[currentGame].playersCount = 0;
    }
    
    function getGameStartDate(uint id) view public returns (uint date) {
        return games[id].beginsAt;
    }
    
    function getGameEndDate(uint id) view public returns (uint date) {
        return games[id].endsAt;
    }
    
    function getGameWinningNumbers(uint id) view public returns (uint[] numbers) {
        return games[id].winningNumbers;
    }
    
    function getGameVolume(uint id) view public returns (uint amount) {
        return games[id].volume;
    }
    
    function getGamePlayersByNumber(uint id, uint number) view public returns (address[] players) {
        return games[id].players[number];
    }

    function getGamePlayersCount(uint id) view public returns (uint count) {
        return games[id].playersCount;
    }
    
    function play (uint number) public payable isValidNumber (number) {
        Game storage game = games[currentGame];
        
        require(now <= game.endsAt);
        
        require(msg.value == game.price);
        
        game.volume += msg.value;
        game.playersCount += 1;
        game.players[number].push(msg.sender);
    }
    
    function addWinningNumber (uint number) public isAdmin gameIsOver isValidNumber (number) {
        Game storage game = games[currentGame];
        
        require(game.winningNumbers.length < winningNumbersLength);
        
        game.winningNumbers.push(number);
    }
    
    function redeem () payable public gameIsOver gameIsNotRedeemed {
        Game storage game = games[currentGame];
        
        require(game.winningNumbers.length == winningNumbersLength);
        
        uint _fee = fee.mul(game.playersCount);
        lastFeeVolume = game.volume.sub(_fee);
        
        require(feeAddress.send(lastFeeVolume));
        
        // game.volume -= lastFeeVolume;
    }
}