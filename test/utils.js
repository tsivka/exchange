const BigNumber = require('bignumber.js');

const gasToUse = 0x47E7C4;

function receiptShouldSucceed (result) {
    return new Promise(function (resolve, reject) {
        if (result.receipt.gasUsed === gasToUse) {
            try {
                assert.notEqual(result.receipt.gasUsed, gasToUse, 'tx failed, used all gas');
            } catch (err) {
                reject(err);
            }
        } else {
            console.log('gasUsed', result.receipt.gasUsed);
            resolve();
        }
    });
}

function receiptShouldFailed (result) {
    return new Promise(function (resolve, reject) {
        if (result.receipt.gasUsed === gasToUse) {
            resolve();
        } else {
            try {
                assert.equal(result.receipt.gasUsed, gasToUse, 'tx succeed, used not all gas');
            } catch (err) {
                reject(err);
            }
        }
    });
}

function catchReceiptShouldFailed (err) {
    if (err.message.indexOf('invalid opcode') === -1 && err.message.indexOf('revert') === -1) {
        throw err;
    }
}


function getEtherBalance (_address) {
    return web3.eth.getBalance(_address);
}

function checkEtherBalance (_address, expectedBalance) {
    const balance = web3.eth.getBalance(_address);

    assert.equal(balance.valueOf(), expectedBalance.valueOf(), 'address balance is not equal');
}

module.exports = {
    receiptShouldSucceed: receiptShouldSucceed,
    receiptShouldFailed: receiptShouldFailed,
    catchReceiptShouldFailed: catchReceiptShouldFailed,
    getEtherBalance: getEtherBalance,
    checkEtherBalance: checkEtherBalance
};
