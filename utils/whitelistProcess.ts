import { defaultAbiCoder } from "ethers/lib/utils";
import { ethers } from "hardhat";
import crypto from "crypto";
import { DOMAIN_SEPARATOR_TYPEHASH } from "./constants";

export async function nonceGenerator(
  userAddress: string,
  secondaryDomainNameLength: number,
  duration: number
): Promise<string> {
  var entropy = "";
  await crypto.randomBytes(48, function (err, buffer) {
    entropy = buffer.toString("hex");
  });

  const t = new Date().getTime().toString();

  return ethers.utils.keccak256(
    ethers.utils.toUtf8Bytes(
      userAddress + secondaryDomainNameLength.toString() + duration.toString() + entropy + t
    )
  );
}

export function generateWhitelistMessage(
  userAddress: string,
  rootName: string,
  secondaryNameLength: number,
  nonce: string,
  duration: number,
  signature: string
) {
  const msg = defaultAbiCoder.encode(
    [
      "tuple(address userAddress, string rootName, uint256 secondaryNameLength, uint256 nonce, uint256 duration, bytes signature)",
    ],
    [
      {
        userAddress,
        rootName,
        secondaryNameLength,
        nonce,
        duration,
        signature,
      },
    ]
  );

  return msg;
}

export function generateMessageHash(
  chainId: number | undefined,
  registrarControllerAddress: string,
  userAddress: string,
  rootName: string,
  secondaryNameLength: number,
  nonce: string,
  duration: number
) {
  if (!chainId) {
    throw Error();
  }

  var msgHash = ethers.utils.keccak256(
    ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "address", "string", "uint256", "uint256", "uint256"],
      [DOMAIN_SEPARATOR_TYPEHASH, userAddress, rootName, secondaryNameLength, nonce, duration]
    )
  );

  const domainSeparator = getDomainSeparator(chainId, registrarControllerAddress);

  const msgHash_2 = ethers.utils.keccak256(
    ethers.utils.solidityPack(
      ["bytes1", "bytes1", "bytes32", "bytes32"],
      ["0x19", "0x01", domainSeparator, msgHash]
    )
  );

  console.log({ offChainMsgHash: msgHash_2, domainSeparator, msgHash });
  return { msgHash: ethers.utils.arrayify(msgHash_2) };
}

export function getDomainSeparator(chainId: number | undefined, contractAddress: string): string {
  return ethers.utils.keccak256(
    ethers.utils.defaultAbiCoder.encode(
      ["bytes32", "uint256", "address"],
      [DOMAIN_SEPARATOR_TYPEHASH, chainId, contractAddress]
    )
  );
}
