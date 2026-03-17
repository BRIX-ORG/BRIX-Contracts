import { expect } from 'chai';
import { ethers } from 'hardhat';
import { HardhatEthersSigner } from '@nomicfoundation/hardhat-ethers/signers';
import { Donate } from '../typechain-types';

describe('Donate Contract', function () {
    let donate: Donate;
    let owner: HardhatEthersSigner;
    let artist: HardhatEthersSigner;
    let platform: HardhatEthersSigner;
    let donor: HardhatEthersSigner;

    beforeEach(async function () {
        [owner, artist, platform, donor] = await ethers.getSigners();

        const DonateFactory = await ethers.getContractFactory('Donate');
        donate = (await DonateFactory.deploy(platform.address)) as any;
        await donate.waitForDeployment();
    });

    it('Should set the right platform fee address', async function () {
        expect(await donate.platformFeeAddress()).to.equal(platform.address);
    });

    it('Should create a new item', async function () {
        const metadataHash = 'ipfs://QmTest123';
        await expect(donate.connect(artist).createItem(metadataHash))
            .to.emit(donate, 'ItemCreated')
            .withArgs(1, metadataHash, artist.address);

        const item = await donate.items(1);
        expect(item.metadataHash).to.equal(metadataHash);
        expect(item.artist).to.equal(artist.address);
        expect(item.totalDonated).to.equal(0n);
    });

    it('Should process a donation and split funds correctly', async function () {
        const metadataHash = 'ipfs://QmTest123';
        await donate.connect(artist).createItem(metadataHash);

        const donationAmount = ethers.parseEther('1.0'); // 1 MATIC/ETH

        await expect(
            donate.connect(donor).donate(1, { value: donationAmount }),
        ).to.changeEtherBalances(
            [donor, artist, platform],
            [-donationAmount, ethers.parseEther('0.9'), ethers.parseEther('0.1')],
        );

        const item = await donate.items(1);
        expect(item.totalDonated).to.equal(donationAmount);
    });
});
