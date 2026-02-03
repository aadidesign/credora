import { gql } from "urql";

export const GET_USER_QUERY = gql`
  query GetUser($id: Bytes!) {
    user(id: $id) {
      id
      address
      tokenId
      hasActiveSBT
      currentScore
      totalScoreUpdates
      activePermissions
      totalPermissionsGranted
      firstActivityAt
      lastActivityAt
    }
  }
`;

export const GET_SCORE_UPDATES_QUERY = gql`
  query GetScoreUpdates($owner: Bytes!, $first: Int!) {
    scoreUpdates(
      where: { owner: $owner }
      first: $first
      orderBy: timestamp
      orderDirection: desc
    ) {
      id
      tokenId
      owner
      oldScore
      newScore
      timestamp
      transactionHash
    }
  }
`;

export const GET_PERMISSIONS_QUERY = gql`
  query GetPermissions($user: Bytes!) {
    permissions(where: { user: $user, isActive: true }) {
      id
      user
      protocol
      grantedAt
      expiresAt
      maxRequests
      usedRequests
      isActive
    }
  }
`;

/** For protocol integrators: stats for a protocol address (aligns with README) */
export const GET_PROTOCOL_STATS_QUERY = gql`
  query GetProtocolStats($id: Bytes!) {
    protocolStats(id: $id) {
      id
      protocol
      totalPermissionsReceived
      activePermissions
      totalAccessUsed
      firstPermissionAt
    }
  }
`;
