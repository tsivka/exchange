const ERC1 = artifacts.require('contracts/ERC1.sol');
const Exchange = artifacts.require('contracts/Exchange.sol');

const BigNumber =require("bignumber.js");
const precision = 1000000000000000000;

contract('ERC1', (accounts) => {
    let instance1;
    let instance2;
    let exchange;
    beforeEach(async function () {
        instance1 = await ERC1.new(
                'Name1',
                'Symb1',
                new BigNumber(100).mul(precision),
                { from: accounts[0] }
            );
        instance2 = await ERC1.new(
            'Name2',
            'Symb2',
            new BigNumber(50).mul(precision),
            { from: accounts[1] }
        );
        exchange = await Exchange.new([instance1.address,instance2.address])
    });

    it('balance1 should  be equal 100 tokens',async function(){
        assert.equal(
            new BigNumber(
                await instance1.balanceOf.call(accounts[0])
            ).valueOf(),
            new BigNumber(100).mul(precision).valueOf(),
            'balance is not equal'
        );
    });

    it('balance2 should  be equal 50 tokens',async function(){

        assert.equal(
            new BigNumber(
                await instance2.balanceOf.call(accounts[1])
            ).valueOf(),
            new BigNumber(50).mul(precision).valueOf(),
            'balance is not equal'
        );
    });

    it('should exchange tokens',async function(){
        await instance2.approve(
            exchange.address,
            new BigNumber(10).mul(precision).valueOf(),
            { from: accounts[1] }
        );
        await instance1.approve(
            exchange.address,
            new BigNumber(10).mul(precision).valueOf(),
            { from: accounts[0] }
        );
        await exchange.createExchangeRequest(
            instance1.address,
            instance2.address,
            new BigNumber(1).mul(precision).valueOf(),
            { from: accounts[0] }
        );
        await exchange.exchangeTokens(
            0,
            { from: accounts[1] }
        );

    });
});
