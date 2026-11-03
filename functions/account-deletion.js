const { ADMIN_EMAIL } = require("./admin-identity");

const DELETED_USER_NAME = "Törölt felhasználó";

function emailIsAdmin(value) {
  return String(value || "").toLowerCase() === ADMIN_EMAIL;
}

/** Saját fiók törölhető, az adminé nem. */
function selfDeleteAllowed(user) {
  if (!user) return { ok: false, reason: "missing" };
  if (user.role === "admin" || emailIsAdmin(user.email)) {
    return { ok: false, reason: "admin" };
  }
  return { ok: true };
}

const REPORT_ACTIONS = new Set(["hide", "delete", "suspend", "close"]);

function reportActionAllowed(action) {
  return REPORT_ACTIONS.has(action);
}

module.exports = {
  DELETED_USER_NAME,
  selfDeleteAllowed,
  reportActionAllowed,
};
