/** Név vagy profilkép változása után a bejegyzések és hozzászólások frissítése. */

function photoOf(data) {
  if (!data) return null;
  return typeof data.photoUrl === "string" && data.photoUrl ? data.photoUrl : null;
}

function nameOf(data) {
  if (!data || typeof data.name !== "string") return "";
  return data.name;
}

/**
 * Létrehozáskor nincs mit frissíteni. Ha a név és a kép ugyanaz, null.
 * Egyébként a bejegyzésekbe írandó mezők.
 */
function authorPropagationPlan(before, after) {
  if (!before || !after) return null;
  const authorName = nameOf(after);
  const authorPhotoUrl = photoOf(after);
  if (nameOf(before) === authorName && photoOf(before) === authorPhotoUrl) {
    return null;
  }
  return { authorName, authorPhotoUrl };
}

function chunk(items, size = 500) {
  const groups = [];
  for (let index = 0; index < items.length; index += size) {
    groups.push(items.slice(index, index + size));
  }
  return groups;
}

/** A tervet alkalmazza a szerző saját bejegyzéseire. */
function applyAuthorPlan(posts, uid, plan) {
  return posts.map((post) => {
    if (post.authorId !== uid) return post;
    return {
      ...post,
      authorName: plan.authorName,
      authorPhotoUrl: plan.authorPhotoUrl,
    };
  });
}

module.exports = {
  authorPropagationPlan,
  chunk,
  applyAuthorPlan,
};
