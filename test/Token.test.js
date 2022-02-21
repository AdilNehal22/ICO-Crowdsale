const BigNumber = web3.BigNumber;
const Token = artifacts.require('Token');

require('chai')
    .use(require('chai-bignumber')(BigNumber))
    .should();

contract('Token', accounts=>{

    const name = 'ICOToken';
    const symbol = 'ICOT';
    const decimal = 18;

    beforeEach(async function(){
        this.token = await Token.new(name, symbol, decimal)
    });

    describe('token attributes', function(){

        it('has the correct name', async function(){
            const name = await this.token.name();
            name.should.equal(name);
        });

        it('has the correct symbol', async function() {
            const symbol = await this.token.symbol();
            symbol.should.equal(symbol);
        });
      
        it('has the correct decimals', async function() {
            const decimals = await this.token.decimals();
            decimals.should.equal(decimal);
        });

    });

});