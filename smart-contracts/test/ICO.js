const {
    time,
    loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const {expect} = require("chai");
const {ethers} = require("hardhat");

describe("ICO", function () {
    // We define a fixture to reuse the same setup in every test.
    // We use loadFixture to run this setup once, snapshot that state,
    // and reset Hardhat Network to that snapshot in every test.
    async function setupEnvironment() {
        const ONE_DAY_IN_SECS = 24 * 60 * 60;
        const RATE = 1e15;
        const invest_ether_amount = 0.01 * RATE;
        const invest_token_amount = 1;
        const icoEndTime = (await time.latest()) + ONE_DAY_IN_SECS;
        const [owner, otherAccount] = await ethers.getSigners();

        const STKNFactory = await ethers.getContractFactory("ICOT");
        const stkn = await STKNFactory.deploy();

        const StknICOFactory = await ethers.getContractFactory("StknICO");
        const stknICO = await StknICOFactory.deploy(
            "0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199",
            stkn.address
        );

        return {stknICO, invest_ether_amount, invest_token_amount, owner, otherAccount, icoEndTime, RATE};
    }

    describe("Invest", function () {
        // it("Should set the right unlockTime", async function () {
        //   const { stknICO, unlockTime } = await loadFixture(setupEnvironment);
        //
        //   expect(await stknICO.unlockTime()).to.equal(unlockTime);
        // });

        it("Should be able to invest", async function () {
            const {stknICO, invest_ether_amount} = await loadFixture(setupEnvironment);
            await stknICO.startICO();
            await expect(stknICO.invest({value: invest_ether_amount})).not.to.be.reverted;
        });

        it("Should not invest after EndTime", async function () {
            const {stknICO, icoEndTime, invest_ether_amount} = await loadFixture(setupEnvironment);
            await stknICO.startICO();
            await time.increaseTo(icoEndTime + 100);
            await expect(stknICO.invest({value: invest_ether_amount})).to.be.revertedWith("ICO already Reached Maximum time limit");
        });

        it("Should not invest larger than MAX Investment", async function () {
            const {stknICO, RATE} = await loadFixture(setupEnvironment);
            await stknICO.startICO();
            await expect(stknICO.invest({value: 6 * RATE})).to.be.revertedWith("Check Min and Max Investment");
        });

        it("Should not invest smaller than MIN Investment", async function () {
            const {stknICO, RATE} = await loadFixture(setupEnvironment);
            await stknICO.startICO();
            await expect(stknICO.invest({value: 0.000001 * RATE})).to.be.revertedWith("Check Min and Max Investment");
        });

        it("Should Transfer Ethereum", async function () {
            const {stknICO, invest_ether_amount, owner} = await loadFixture(setupEnvironment);
            await stknICO.startICO();
            await expect(stknICO.invest({value: invest_ether_amount})).to.changeEtherBalances(
                [owner, stknICO],
                [-invest_ether_amount, 0]
            );
        });

    });
});
