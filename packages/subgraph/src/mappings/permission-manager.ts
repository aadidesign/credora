import { BigInt, Bytes } from "@graphprotocol/graph-ts";
import {
  AccessGranted,
  AccessRevoked,
  AccessUsed,
} from "../generated/PermissionManager/PermissionManager";
import {
  Permission,
  PermissionUsage,
  User,
  ProtocolStats,
  DailyStats,
} from "../generated/schema";

function getOrCreateUser(address: Bytes): User {
  let user = User.load(address);
  if (!user) {
    user = new User(address);
    user.address = address;
    user.tokenId = null;
    user.hasActiveSBT = false;
    user.currentScore = null;
    user.totalScoreUpdates = BigInt.fromI32(0);
    user.activePermissions = BigInt.fromI32(0);
    user.totalPermissionsGranted = BigInt.fromI32(0);
    user.firstActivityAt = BigInt.fromI32(0);
    user.lastActivityAt = BigInt.fromI32(0);
    user.save();
  }
  return user;
}

function getOrCreateProtocolStats(protocol: Bytes): ProtocolStats {
  let stats = ProtocolStats.load(protocol);
  if (!stats) {
    stats = new ProtocolStats(protocol.toHexString());
    stats.protocol = protocol;
    stats.totalPermissionsReceived = BigInt.fromI32(0);
    stats.activePermissions = BigInt.fromI32(0);
    stats.totalAccessUsed = BigInt.fromI32(0);
    stats.firstPermissionAt = BigInt.fromI32(0);
    stats.save();
  }
  return stats;
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
  if (field == "grant") stats.permissionGrantCount = stats.permissionGrantCount.plus(BigInt.fromI32(delta));
  else if (field == "revoke") stats.permissionRevokeCount = stats.permissionRevokeCount.plus(BigInt.fromI32(delta));
  else if (field == "usage") stats.accessUsageCount = stats.accessUsageCount.plus(BigInt.fromI32(delta));
  stats.save();
}

export function handleAccessGranted(event: AccessGranted): void {
  const userAddr = event.params.user;
  const protocol = event.params.protocol;
  const expiresAt = event.params.expiresAt;
  const maxRequests = event.params.maxRequests;
  const permissionHash = event.params.permissionHash;

  const id = userAddr.toHexString().concat("-").concat(protocol.toHexString());
  const permission = new Permission(id);
  permission.user = userAddr;
  permission.protocol = protocol;
  permission.grantedAt = event.block.timestamp;
  permission.expiresAt = expiresAt;
  permission.maxRequests = maxRequests;
  permission.usedRequests = BigInt.fromI32(0);
  permission.isActive = true;
  permission.permissionHash = permissionHash;
  permission.createdTx = event.transaction.hash;
  permission.save();

  const user = getOrCreateUser(userAddr);
  user.activePermissions = user.activePermissions.plus(BigInt.fromI32(1));
  user.totalPermissionsGranted = user.totalPermissionsGranted.plus(BigInt.fromI32(1));
  if (user.firstActivityAt.equals(BigInt.fromI32(0))) {
    user.firstActivityAt = event.block.timestamp;
  }
  user.lastActivityAt = event.block.timestamp;
  user.save();

  const protocolStats = getOrCreateProtocolStats(protocol);
  protocolStats.totalPermissionsReceived = protocolStats.totalPermissionsReceived.plus(BigInt.fromI32(1));
  protocolStats.activePermissions = protocolStats.activePermissions.plus(BigInt.fromI32(1));
  if (protocolStats.firstPermissionAt.equals(BigInt.fromI32(0))) {
    protocolStats.firstPermissionAt = event.block.timestamp;
  }
  protocolStats.save();

  updateDailyStats(event.block.timestamp, "grant", 1);
}

export function handleAccessRevoked(event: AccessRevoked): void {
  const userAddr = event.params.user;
  const protocol = event.params.protocol;

  const id = userAddr.toHexString().concat("-").concat(protocol.toHexString());
  const permission = Permission.load(id);
  if (permission) {
    permission.isActive = false;
    permission.save();
  }

  const user = getOrCreateUser(userAddr);
  if (user.activePermissions.gt(BigInt.fromI32(0))) {
    user.activePermissions = user.activePermissions.minus(BigInt.fromI32(1));
  }
  user.lastActivityAt = event.block.timestamp;
  user.save();

  const protocolStats = getOrCreateProtocolStats(protocol);
  if (protocolStats.activePermissions.gt(BigInt.fromI32(0))) {
    protocolStats.activePermissions = protocolStats.activePermissions.minus(BigInt.fromI32(1));
  }
  protocolStats.save();

  updateDailyStats(event.block.timestamp, "revoke", 1);
}

export function handleAccessUsed(event: AccessUsed): void {
  const userAddr = event.params.user;
  const protocol = event.params.protocol;
  const remainingRequests = event.params.remainingRequests;

  const usageId = event.transaction.hash.concatI32(event.logIndex.toI32());
  const usage = new PermissionUsage(usageId.toHexString());
  usage.user = userAddr;
  usage.protocol = protocol;
  usage.remainingRequests = remainingRequests;
  usage.timestamp = event.block.timestamp;
  usage.transactionHash = event.transaction.hash;
  usage.save();

  const id = userAddr.toHexString().concat("-").concat(protocol.toHexString());
  const permission = Permission.load(id);
  if (permission) {
    permission.usedRequests = permission.maxRequests.minus(remainingRequests);
    permission.save();
  }

  const protocolStats = getOrCreateProtocolStats(protocol);
  protocolStats.totalAccessUsed = protocolStats.totalAccessUsed.plus(BigInt.fromI32(1));
  protocolStats.save();

  updateDailyStats(event.block.timestamp, "usage", 1);
}
