import { ethers } from "ethers";
import { keccak256, toUtf8Bytes } from "ethers/lib/utils";
import { defaultAbiCoder } from "ethers/lib/utils";

function getBytesTokenId(rootName: string, secondaryName: string) {
  const firstHash = keccak256(
    defaultAbiCoder.encode(
      ["address", "bytes32"],
      [ethers.constants.AddressZero, keccak256(toUtf8Bytes(rootName))]
    )
  );

  const tokenId = keccak256(
    defaultAbiCoder.encode(
      ["bytes32", "bytes32"],
      [firstHash, keccak256(toUtf8Bytes(secondaryName))]
    )
  );

  return tokenId;
}

// test
const bytesTokenId = getBytesTokenId("doaverse", "do");
console.log({ bytesTokenId });
