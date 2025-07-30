import { Wallet, JsonRpcProvider, Contract } from "ethers";
import {
  LimitOrder,
  MakerTraits,
  Address,
  Api,
  getLimitOrderV4Domain,
} from "@1inch/limit-order-sdk";

// Standard ERC-20 ABI fragment (used for token approval)
const erc20AbiFragment = [
  "function approve(address spender, uint256 amount) external returns (bool)",
  "function allowance(address owner, address spender) external view returns (uint256)",
];

// Use environment variables to manage private keys securely
const privKey = process.env.PRIVATE_KEY;
const chainId = 1; // Ethereum mainnet

const provider = new JsonRpcProvider("https://cloudflare-eth.com/");
const wallet = new Wallet(privKey, provider);

const makerAsset = "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"; // USDC
const takerAsset = "0x111111111117dc0aa78b770fa6a738034120c302"; // 1INCH

const makingAmount = 1_000_000n; // 1 USDC (in 6 decimals)
const takingAmount = 1_000_000_000_000_000_00n; // 1 1INCH (18 decimals)

const expiresIn = 120n; // seconds
const expiration = BigInt(Math.floor(Date.now() / 1000)) + expiresIn;

import { MaxUint256 } from "ethers";

const domain = getLimitOrderV4Domain(chainId);
const limitOrderContractAddress = domain.verifyingContract;

const makerAssetContract = new Contract(makerAsset, erc20AbiFragment, wallet);

const currentAllowance = await makerAssetContract.allowance(
  wallet.address,
  limitOrderContractAddress,
);

if (currentAllowance < makingAmount) {
  // Approve just the necessary amount or the full MaxUint256 to avoid repeated approvals
  const approveTx = await makerAssetContract.approve(
    limitOrderContractAddress,
    makingAmount,
  );
  await approveTx.wait();
}

const makerTraits = new MakerTraits()
  .withExpiration(expiration)
  .allowPartialFills()
  .allowMultipleFills();

  const order = new LimitOrder({
  makerAsset: new Address(makerAsset),
  takerAsset: new Address(takerAsset),
  makingAmount,
  takingAmount,
  maker: new Address(wallet.address),
  receiver: new Address(wallet.address),
  salt: BigInt(Math.floor(Math.random() * 1e8)), // must be unique for each order
  makerTraits,
});

const typedData = order.getTypedData(domain);

// Adapt domain format for signTypedData
const domainForSignature = {
  ...typedData.domain,
  chainId: chainId,
};

const signature = await wallet.signTypedData(
  domainForSignature,
  { Order: typedData.types.Order },
  typedData.message,
);

