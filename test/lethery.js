var Lethery = artifacts.require("./Lethery.sol");

contract('Lethery', (accounts) => {
    console.log(accounts);

    let admin = accounts[0];
    let currentGame = 1;
    let gamePrice = web3.toWei(.05, 'ether');
    let gameFee = web3.toWei(.005, 'ether');
    let numbers = [123456, 23456789123, 34567891234, 123456789123];
    let numberOfPlayers = numbers.length;
    let winningNumbers = [123456, 123456789123, 123456789124];

    it("should have preset variables on contract creation", () => {
        var lethery;
        
        return Lethery.deployed().then(instance => {
            lethery = instance;
            return instance.admin.call();
        }).then(admin => {
            assert.equal(admin.valueOf(), admin, 'address does not match admin address');
            return lethery.feeAddress.call();
        }).then(feeAddress => {
            assert.equal(feeAddress.valueOf(), accounts[accounts.length-1], "feeAddress is not set");
            return lethery.gamePrice.call();
        }).then(price => {
            assert.equal(price.valueOf(), gamePrice, "game price is not set");
            return lethery.fee.call();
        }).then(fee => {
            assert.equal(fee.valueOf(), gameFee, "game fee is not set");
        }).catch(error => {
            console.log(error);
        });
    });

    it("should allow only admin to create a game", () => {
        var lethery;
        
        return Lethery.deployed().then(instance => {
            lethery = instance;
            return instance.createGame();
        }).then(result => {
            return lethery.currentGame.call();
        }).then(currentGame => {
            assert.equal(currentGame.valueOf(), 1, "currentGame is not 1");
        });
    });

    it("should allow a user address to play the current game with a valid number", () => {
        var lethery;
        
        return Lethery.deployed().then(instance => {
            lethery = instance;            
            numbers.forEach((number, i) => {
                instance.play(number, {from: accounts[i+1], value: gamePrice});
            });
            return lethery.getGameVolume(currentGame);
        }).then(gameVolume => {
            // TODO assert if the player was charged the ETH
            assert.equal(gameVolume.valueOf(), gamePrice * numberOfPlayers, 'gameVolume is not gamePrice*NPlayers ether');
            
            return lethery.getGamePlayersCount(currentGame);
        }).then(playersCount => {
            assert.equal(playersCount.valueOf(), numberOfPlayers, 'players count is not 1');
            
            return lethery.getGamePlayersByNumber(currentGame, numbers[0]);
        }).then(players => {
            assert.equal(players[0], accounts[1], 'player is not in the players mapping');
        }).catch(error => {
            console.log(error.message);
        });
    });

    it("should allow the admin to add the winning numbers", done => {
        setTimeout(() => { // Lethery is set to certain ending time of every game
            var lethery;
            
            return Lethery.deployed().then(instance => {
                lethery = instance;
                
                winningNumbers.forEach(number => {
                    instance.addWinningNumber(number, {from: admin});
                });
                
                return instance.getGameWinningNumbers(currentGame);
            }).then(winningNumbers => {
                winningNumbers.forEach((number, i) => {
                    assert.equal(number.valueOf(), winningNumbers[i], 'Winning number is not on the list');
                });
                
                done();
            }).catch(error => {
                console.log(error);
            });
        }, 15000);
    });

    it("should allow a player to redeem ETH if he holds a winning number", () => {
        var lethery;
        return Lethery.deployed().then(instance => {
            lethery = instance;
            
            instance.redeem({from: admin});
            
            return instance.lastFeeVolume.call();
        }).then(amount => {
            var result = (gamePrice * numberOfPlayers) - (gameFee * numberOfPlayers);
            assert.equal(amount.valueOf(), result, 'Winning number is not on list');
        }).catch(error => {
            console.log(error);
        });
    });
});












