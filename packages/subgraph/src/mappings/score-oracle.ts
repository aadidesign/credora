import { BigInt, Bytes } from "@graphprotocol/graph-ts";
import {
  ScoreUpdateRequested,
  ScoreUpdated,
  OracleAdded,
  OracleRemoved,
} from "../generated/ScoreOracle/ScoreOracle";
import { Oracle, ScoreRequest } from "../generated/schema";

function getOrCreateOracle(address: Bytes): Oracle {
  const id = address.toHexString();
  let oracle = Oracle.load(id);
  if (!oracle) {
    oracle = new Oracle(id);
    oracle.address = address;
    oracle.isActive = true;
    oracle.addedAt = BigInt.fromI32(0);
    oracle.updatesSubmitted = BigInt.fromI32(0);
    oracle.save();
  }
  return oracle;
}

export function handleScoreUpdateRequested(event: ScoreUpdateRequested): void {
  const user = event.params.user;
  const requestId = event.params.requestId;

  const id = requestId.toString();
  const request = new ScoreRequest(id);
  request.user = user;
  request.requestedAt = event.block.timestamp;
  request.status = "PENDING";
  request.requestTx = event.transaction.hash;
  request.save();
}

export function handleOracleScoreUpdated(event: ScoreUpdated): void {
  const oracleAddr = event.params.oracle;
  const oracle = getOrCreateOracle(oracleAddr);
  oracle.updatesSubmitted = oracle.updatesSubmitted.plus(BigInt.fromI32(1));
  oracle.save();
}

export function handleOracleAdded(event: OracleAdded): void {
  const oracleAddr = event.params.oracle;
  const oracle = getOrCreateOracle(oracleAddr);
  oracle.isActive = true;
  oracle.addedAt = event.block.timestamp;
  oracle.save();
}

export function handleOracleRemoved(event: OracleRemoved): void {
  const oracleAddr = event.params.oracle;
  const oracle = getOrCreateOracle(oracleAddr);
  oracle.isActive = false;
  oracle.save();
}
