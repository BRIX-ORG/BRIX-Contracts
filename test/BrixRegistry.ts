import { expect } from 'chai';
import { ethers } from 'hardhat';
import { HardhatEthersSigner } from '@nomicfoundation/hardhat-ethers/signers';
import { BrixRegistry } from '../typechain-types';

describe('BrixRegistry', function () {
    let registry: BrixRegistry;
    let owner: HardhatEthersSigner;
    let platform: HardhatEthersSigner;
    let artist: HardhatEthersSigner;
    let donor: HardhatEthersSigner;
    let other: HardhatEthersSigner;

    const IPFS_FEE = ethers.parseEther('0.001'); // 0.001 MATIC
    const VALID_BRICK_ID = ethers.id('9498704e-74a6-4ebe-9349-941143c19f67');
    const VALID_BRICK_ID_2 = ethers.id('e03660ef-7e89-48d5-b177-14a2288cc269');

    beforeEach(async function () {
        [owner, platform, artist, donor, other] = await ethers.getSigners();

        const Factory = await ethers.getContractFactory('BrixRegistry');
        registry = (await Factory.deploy(platform.address, IPFS_FEE)) as unknown as BrixRegistry;
        await registry.waitForDeployment();
    });

    // ═══════════════════════════════════════════════════════
    //  Deployment
    // ═══════════════════════════════════════════════════════

    describe('Deployment', function () {
        it('should set the correct owner', async function () {
            expect(await registry.owner()).to.equal(owner.address);
        });

        it('should set the correct platform fee address', async function () {
            expect(await registry.platformFeeAddress()).to.equal(platform.address);
        });

        it('should set the correct IPFS fee', async function () {
            expect(await registry.ipfsFee()).to.equal(IPFS_FEE);
        });

        it('should set the default platform fee percent to 10', async function () {
            expect(await registry.platformFeePercent()).to.equal(10n);
        });

        it('should revert if platform fee address is zero', async function () {
            const Factory = await ethers.getContractFactory('BrixRegistry');
            await expect(
                Factory.deploy(ethers.ZeroAddress, IPFS_FEE),
            ).to.be.revertedWithCustomError(registry, 'InvalidAddress');
        });
    });

    // ═══════════════════════════════════════════════════════
    //  FLOW 1 — payForIPFS
    // ═══════════════════════════════════════════════════════

    describe('payForIPFS', function () {
        it('should emit PaidForIPFS event with correct params', async function () {
            await expect(registry.connect(artist).payForIPFS(VALID_BRICK_ID, { value: IPFS_FEE }))
                .to.emit(registry, 'PaidForIPFS')
                .withArgs(artist.address, VALID_BRICK_ID);
        });

        it('should revert if brickId is zero', async function () {
            await expect(
                registry.connect(artist).payForIPFS(ethers.ZeroHash, { value: IPFS_FEE }),
            ).to.be.revertedWithCustomError(registry, 'InvalidBrickId');
        });

        it('should accept overpayment and refund the excess', async function () {
            const overpay = ethers.parseEther('0.01');
            await expect(
                registry.connect(artist).payForIPFS(VALID_BRICK_ID, { value: overpay }),
            ).to.changeEtherBalances([artist, registry], [-IPFS_FEE, IPFS_FEE]);
        });

        it('should revert with InsufficientFee if not enough', async function () {
            const tooLow = ethers.parseEther('0.0001');
            await expect(
                registry.connect(artist).payForIPFS(VALID_BRICK_ID, { value: tooLow }),
            ).to.be.revertedWithCustomError(registry, 'InsufficientFee');
        });

        it('should revert AlreadyPaid if same user pays same brickId twice', async function () {
            await registry.connect(artist).payForIPFS(VALID_BRICK_ID, { value: IPFS_FEE });
            await expect(
                registry.connect(artist).payForIPFS(VALID_BRICK_ID, { value: IPFS_FEE }),
            ).to.be.revertedWithCustomError(registry, 'AlreadyPaid');
        });

        it('should allow a different user to pay for the SAME brickId (anti-MEV front-running fix)', async function () {
            await registry.connect(artist).payForIPFS(VALID_BRICK_ID, { value: IPFS_FEE });
            await expect(
                registry.connect(other).payForIPFS(VALID_BRICK_ID, { value: IPFS_FEE }),
            ).to.emit(registry, 'PaidForIPFS');
        });
    });

    // ═══════════════════════════════════════════════════════
    //  FLOW 2 — mint
    // ═══════════════════════════════════════════════════════

    describe('mint', function () {
        const ipfsCid = 'QmTestCid123456789';

        beforeEach(async function () {
            await registry.connect(artist).payForIPFS(VALID_BRICK_ID, { value: IPFS_FEE });
        });

        it('should create a brick and emit BrickCreated', async function () {
            await expect(registry.connect(artist).mint(VALID_BRICK_ID, ipfsCid))
                .to.emit(registry, 'BrickCreated')
                .withArgs(1n, artist.address, ipfsCid);
        });

        it('should store correct brick data', async function () {
            await registry.connect(artist).mint(VALID_BRICK_ID, ipfsCid);
            const [creator, cid, totalDonated] = await registry.getBrick(1);
            expect(creator).to.equal(artist.address);
            expect(cid).to.equal(ipfsCid);
            expect(totalDonated).to.equal(0n);
        });

        it('should revert InvalidBrickId for empty (zero) brickId', async function () {
            await expect(
                registry.connect(artist).mint(ethers.ZeroHash, ipfsCid),
            ).to.be.revertedWithCustomError(registry, 'InvalidBrickId');
        });

        it('should revert InvalidCID for empty CID', async function () {
            await expect(
                registry.connect(artist).mint(VALID_BRICK_ID, ''),
            ).to.be.revertedWithCustomError(registry, 'InvalidCID');
        });

        it('should revert NotPaidForIPFS if user never paid for that specific brickId', async function () {
            await expect(
                registry.connect(other).mint(VALID_BRICK_ID, ipfsCid),
            ).to.be.revertedWithCustomError(registry, 'NotPaidForIPFS');
        });

        it('should revert AlreadyMinted if trying to mint same brick twice', async function () {
            await registry.connect(artist).mint(VALID_BRICK_ID, ipfsCid);
            await expect(
                registry.connect(artist).mint(VALID_BRICK_ID, 'QmAnotherCID'),
            ).to.be.revertedWithCustomError(registry, 'AlreadyMinted');
        });
    });

    // ═══════════════════════════════════════════════════════
    //  FLOW 3 — donate & withdrawDonation (Pull-Payment)
    // ═══════════════════════════════════════════════════════

    describe('donate & withdrawDonation (Pull Payment)', function () {
        const ipfsCid = 'QmTestCid123456789';

        beforeEach(async function () {
            await registry.connect(artist).payForIPFS(VALID_BRICK_ID, { value: IPFS_FEE });
            await registry.connect(artist).mint(VALID_BRICK_ID, ipfsCid);
        });

        it('should split donation into pendingWithdrawals', async function () {
            const donationAmount = ethers.parseEther('1.0');
            const expectedArtist = ethers.parseEther('0.9');
            const expectedPlatform = ethers.parseEther('0.1');

            await expect(
                registry.connect(donor).donate(1, { value: donationAmount }),
            ).to.changeEtherBalances([donor, registry], [-donationAmount, donationAmount]);

            expect(await registry.pendingWithdrawals(artist.address)).to.equal(expectedArtist);
            expect(await registry.pendingWithdrawals(platform.address)).to.equal(expectedPlatform);
            expect(await registry.totalPendingDonations()).to.equal(donationAmount);
        });

        it('should update totalDonated on the brick', async function () {
            const amount1 = ethers.parseEther('0.5');
            const amount2 = ethers.parseEther('0.3');

            await registry.connect(donor).donate(1, { value: amount1 });
            await registry.connect(other).donate(1, { value: amount2 });

            const [, , totalDonated] = await registry.getBrick(1);
            expect(totalDonated).to.equal(amount1 + amount2);
        });

        it('allow users to withdraw their pending donations (pull-payment)', async function () {
            const donationAmount = ethers.parseEther('1.0');
            await registry.connect(donor).donate(1, { value: donationAmount });

            const expectedArtist = ethers.parseEther('0.9');
            const expectedPlatform = ethers.parseEther('0.1');

            await expect(registry.connect(artist).withdrawDonation()).to.changeEtherBalances(
                [registry, artist],
                [-expectedArtist, expectedArtist],
            );

            await expect(registry.connect(platform).withdrawDonation()).to.changeEtherBalances(
                [registry, platform],
                [-expectedPlatform, expectedPlatform],
            );

            expect(await registry.pendingWithdrawals(artist.address)).to.equal(0n);
            expect(await registry.pendingWithdrawals(platform.address)).to.equal(0n);
            expect(await registry.totalPendingDonations()).to.equal(0n);
        });

        it('should revert ZeroWithdrawal if nothing to withdraw', async function () {
            await expect(registry.connect(other).withdrawDonation()).to.be.revertedWithCustomError(
                registry,
                'ZeroWithdrawal',
            );
        });
    });

    // ═══════════════════════════════════════════════════════
    //  Admin Functions
    // ═══════════════════════════════════════════════════════

    describe('Admin Functions', function () {
        describe('withdrawIpfsFees', function () {
            it('should withdraw accumulated IPFS fees and emit event', async function () {
                await registry.connect(artist).payForIPFS(VALID_BRICK_ID, { value: IPFS_FEE });
                await registry.connect(other).payForIPFS(VALID_BRICK_ID_2, { value: IPFS_FEE });

                const tx = await registry.connect(owner).withdrawIpfsFees();
                await expect(tx)
                    .to.emit(registry, 'FeesWithdrawn')
                    .withArgs(owner.address, IPFS_FEE * 2n);
                await expect(tx).to.changeEtherBalance(owner, IPFS_FEE * 2n);
            });

            it('should revert ZeroWithdrawal if no fees collected', async function () {
                await expect(
                    registry.connect(owner).withdrawIpfsFees(),
                ).to.be.revertedWithCustomError(registry, 'ZeroWithdrawal');
            });
        });

        describe('withdrawStuckFunds', function () {
            it('should withdraw only unaccounted-for balance', async function () {
                await registry.connect(artist).payForIPFS(VALID_BRICK_ID, { value: IPFS_FEE });
                await registry.connect(artist).mint(VALID_BRICK_ID, 'QmTest');
                await registry.connect(donor).donate(1, { value: ethers.parseEther('1.0') });

                // Send raw ETH to trigger the receive() fallback
                await donor.sendTransaction({
                    to: await registry.getAddress(),
                    value: ethers.parseEther('5.0'),
                });

                const stuckAmount = ethers.parseEther('5.0');
                const accountedFor = IPFS_FEE + ethers.parseEther('1.0');

                const tx = await registry.connect(owner).withdrawStuckFunds();
                await expect(tx)
                    .to.emit(registry, 'StuckFundsWithdrawn')
                    .withArgs(owner.address, stuckAmount);
                await expect(tx).to.changeEtherBalance(owner, stuckAmount);

                const balanceAfter = await ethers.provider.getBalance(await registry.getAddress());
                expect(balanceAfter).to.equal(accountedFor);
            });

            it('should revert with NoStuckFunds if nothing is stuck', async function () {
                await registry.connect(artist).payForIPFS(VALID_BRICK_ID, { value: IPFS_FEE });
                await expect(
                    registry.connect(owner).withdrawStuckFunds(),
                ).to.be.revertedWithCustomError(registry, 'NoStuckFunds');
            });
        });
    });

    // ═══════════════════════════════════════════════════════
    //  Pausable
    // ═══════════════════════════════════════════════════════

    describe('Pausable', function () {
        const ipfsCid = 'QmTestCid123456789';

        beforeEach(async function () {
            await registry.connect(artist).payForIPFS(VALID_BRICK_ID, { value: IPFS_FEE });
            await registry.connect(artist).mint(VALID_BRICK_ID, ipfsCid);
            await registry.connect(owner).pause();
        });

        it('should revert operations when paused', async function () {
            await expect(
                registry.connect(other).payForIPFS(VALID_BRICK_ID_2, { value: IPFS_FEE }),
            ).to.be.revertedWithCustomError(registry, 'EnforcedPause');

            await registry.connect(owner).unpause();
            await registry.connect(other).payForIPFS(VALID_BRICK_ID_2, { value: IPFS_FEE });
            await registry.connect(owner).pause();

            await expect(
                registry.connect(other).mint(VALID_BRICK_ID_2, 'QmNew'),
            ).to.be.revertedWithCustomError(registry, 'EnforcedPause');

            await expect(
                registry.connect(donor).donate(1, { value: ethers.parseEther('1.0') }),
            ).to.be.revertedWithCustomError(registry, 'EnforcedPause');
        });

        it('should allow withdrawals even when paused', async function () {
            await registry.connect(owner).unpause();
            await registry.connect(donor).donate(1, { value: ethers.parseEther('1.0') });
            await registry.connect(owner).pause();

            // Artist can still rescue funds
            await expect(registry.connect(artist).withdrawDonation()).to.changeEtherBalance(
                artist,
                ethers.parseEther('0.9'),
            );
        });
    });
});
