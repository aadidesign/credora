import { BigInt, Bytes } from "@graphprotocol/graph-ts";
import {
  ScoreMinted,
  ScoreUpdated,
  Transfer,
} from "../generated/ScoreSBT/ScoreSBT";
import { CreditScore, ScoreUpdate, User, DailyStats } from "../generated/schema";

function getOrCreateUser(address: Bytes): User {
  const id = address.toHexString();
  let user = User.load(id);
  if (!user) {
    user = new User(id);
    user.address = address;
    user.hasActiveSBT = false;
    user.currentScore = BigInt.fromI32(0);
    user.totalScoreUpdates = BigInt.fromI32(0);
    user.activePermissions = BigInt.fromI32(0);
    user.totalPermissionsGranted = BigInt.fromI32(0);
    user.firstActivityAt = BigInt.fromI32(0);
    user.lastActivityAt = BigInt.fromI32(0);
    user.save();
  }
  return user;
}

function updateDailyStats(blockTimestamp: BigInt, field: string, delta: i32): void {
  const dayStart = blockTimestamp.toI32() / 86400;
  const id = dayStart.toString();
  let stats = DailyStats.load(id);
  if (!stats) {
    stats = new DailyStats(id);
    stats.date = BigInt.fromI32(dayStart * 86400);
    stats.mintCount = BigInt.fromI32(0);
    stats.updateCount = BigInt.fromI32(0);
    stats.permissionGrantCount = BigInt.fromI32(0);
    stats.permissionRevokeCount = BigInt.fromI32(0);
    stats.accessUsageCount = BigInt.fromI32(0);
  }
  if (field == "mint") stats.mintCount = stats.mintCount.plus(BigInt.fromI32(delta));
  else if (field == "update") stats.updateCount = stats.updateCount.plus(BigInt.fromI32(delta));
  stats.save();
}

export function handleScoreMinted(event: ScoreMinted): void {
  const owner = event.params.owner;
  const tokenId = event.params.tokenId;

  const score = new CreditScore(tokenId.toString());
  score.owner = owner;
  score.score = BigInt.fromI32(0);
  score.lastUpdated = event.block.timestamp;
  score.dataVersion = BigInt.fromI32(1);
  score.scoreProof = Bytes.fromHexString("0x00") as Bytes;
  score.updateCount = BigInt.fromI32(0);
  score.createdAt = event.block.timestamp;
  score.createdTx = event.transaction.hash;
  score.save();

  const user = getOrCreateUser(owner);
  user.tokenId = tokenId;
  user.hasActiveSBT = true;
  user.currentScore = BigInt.fromI32(0);
  if (user.firstActivityAt.equals(BigInt.fromI32(0))) {
    user.firstActivityAt = event.block.timestamp;
  }
  user.lastActivityAt = event.block.timestamp;
  user.save();

  updateDailyStats(event.block.timestamp, "mint", 1);
}

export function handleScoreUpdated(event: ScoreUpdated): void {
  const tokenId = event.params.tokenId;
  const oldScore = event.params.oldScore;
  const newScore = event.params.newScore;
  const updatedBy = event.params.updatedBy;

  const score = CreditScore.load(tokenId.toString());
  if (!score) return;

  const scoreUpdateId = event.transaction.hash.concatI32(event.logIndex.toI32());
  const scoreUpdate = new ScoreUpdate(scoreUpdateId.toHexString());
  scoreUpdate.tokenId = tokenId;
  scoreUpdate.owner = score.owner;
  scoreUpdate.oldScore = oldScore;
  scoreUpdate.newScore = newScore;
  scoreUpdate.dataVersion = BigInt.fromI32(1);
  scoreUpdate.updatedBy = updatedBy;
  scoreUpdate.timestamp = event.block.timestamp;
  scoreUpdate.transactionHash = event.transaction.hash;
  scoreUpdate.save();

  score.score = newScore;
  score.lastUpdated = event.block.timestamp;
  score.updateCount = score.updateCount.plus(BigInt.fromI32(1));
  score.save();

  const user = getOrCreateUser(score.owner);
  user.currentScore = newScore;
  user.totalScoreUpdates = user.totalScoreUpdates.plus(BigInt.fromI32(1));
  user.lastActivityAt = event.block.timestamp;
  user.save();

  updateDailyStats(event.block.timestamp, "update", 1);
}

export function handleTransfer(event: Transfer): void {
  const to = event.params.to;
  const tokenId = event.params.tokenId;
  const from = event.params.from;

  const zero = Bytes.fromHexString("0x0000000000000000000000000000000000000000") as Bytes;
  if (from.equals(zero)) {
  } else if (to.equals(zero)) {
    const user = getOrCreateUser(from);
    user.hasActiveSBT = false;
    user.tokenId = null;
    user.currentScore = null;
    user.save();
  }
}
