const test = require("node:test");
const assert = require("node:assert/strict");
const {
  authorPropagationPlan,
  chunk,
  applyAuthorPlan,
} = require("../profile-sync");

test("névváltozás után a bejegyzések authorName-je frissül", () => {
  const plan = authorPropagationPlan(
    { name: "Kovács Anna", photoUrl: "https://old" },
    { name: "Kovács Anna Mária", photoUrl: "https://old" },
  );
  assert.deepEqual(plan, {
    authorName: "Kovács Anna Mária",
    authorPhotoUrl: "https://old",
  });
  const posts = applyAuthorPlan(
    [
      { id: "p1", authorId: "coach", authorName: "Kovács Anna", text: "Edzés" },
      { id: "p2", authorId: "other", authorName: "Más", text: "Hír" },
    ],
    "coach",
    plan,
  );
  assert.equal(posts[0].authorName, "Kovács Anna Mária");
  assert.equal(posts[1].authorName, "Más");
});

test("változatlan név és kép nem írja újra a bejegyzéseket", () => {
  assert.equal(
    authorPropagationPlan(
      { name: "Kovács Anna", photoUrl: null },
      { name: "Kovács Anna" },
    ),
    null,
  );
});

test("az 500-as csomagok külön batchbe kerülnek", () => {
  const docs = Array.from({ length: 501 }, (_, index) => index);
  const groups = chunk(docs, 500);
  assert.equal(groups.length, 2);
  assert.equal(groups[0].length, 500);
  assert.equal(groups[1].length, 1);
});
