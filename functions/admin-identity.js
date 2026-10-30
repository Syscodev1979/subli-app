const ADMIN_EMAIL = "info@sarosigyorgy.hu";
const DELETED_NAME = "Törölt tag";

function tokenIsAdmin(token) {
  if (!token || typeof token !== "object") return false;
  return token.email === ADMIN_EMAIL;
}

function userRecordIsAdmin(data) {
  if (!data) return false;
  return (
    data.role === "admin" &&
    data.status === "active" &&
    String(data.email || "").toLowerCase() === ADMIN_EMAIL
  );
}

function sameIds(left, right) {
  const a = Array.isArray(left) ? [...left].map(String).sort() : [];
  const b = Array.isArray(right) ? [...right].map(String).sort() : [];
  return a.length === b.length && a.every((id, index) => id === b[index]);
}

/** Szerep, státusz vagy csoport változása. Törlésnél null, azt a deleteMember naplózza. */
function memberAuditPlan(before, after) {
  if (!after) return null;
  const changes = [];
  if ((before?.role ?? null) !== (after.role ?? null)) changes.push("role");
  if ((before?.status ?? null) !== (after.status ?? null)) changes.push("status");
  if (!sameIds(before?.groupIds, after.groupIds)) changes.push("groups");
  if (changes.length === 0) return null;
  return {
    actorId: typeof after.auditBy === "string" ? after.auditBy : null,
    action: changes.join("+"),
    before: {
      role: before?.role ?? null,
      status: before?.status ?? null,
      groupIds: Array.isArray(before?.groupIds) ? before.groupIds : [],
    },
    after: {
      role: after.role ?? null,
      status: after.status ?? null,
      groupIds: Array.isArray(after.groupIds) ? after.groupIds : [],
    },
  };
}

function deletionGuard({ callerId, targetId, target }) {
  if (!target) return { ok: false, reason: "missing" };
  if (callerId === targetId) return { ok: false, reason: "self" };
  if (target.role === "admin" || String(target.email || "").toLowerCase() === ADMIN_EMAIL) {
    return { ok: false, reason: "admin" };
  }
  return { ok: true };
}

function unlinkPlan(target) {
  const childIds = Array.isArray(target?.childIds) ? target.childIds.filter(Boolean) : [];
  const parentIds = Array.isArray(target?.parentIds) ? target.parentIds.filter(Boolean) : [];
  return { childIds, parentIds };
}

function withoutMember(ids, targetId) {
  return (Array.isArray(ids) ? ids : []).filter((id) => id !== targetId);
}

module.exports = {
  ADMIN_EMAIL,
  DELETED_NAME,
  tokenIsAdmin,
  userRecordIsAdmin,
  memberAuditPlan,
  deletionGuard,
  unlinkPlan,
  withoutMember,
};
