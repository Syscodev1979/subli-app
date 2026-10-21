import { readFileSync } from "node:fs";
import { after, before, beforeEach, test } from "node:test";
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from "@firebase/rules-unit-testing";
import { doc, setDoc, updateDoc, Timestamp } from "firebase/firestore";

const projectId = "demo-gastroyal-rules";
const createdAt = Timestamp.fromDate(new Date("2026-01-15T10:00:00Z"));
const birthDate = Timestamp.fromDate(new Date("2012-03-04T00:00:00Z"));
const laterBirthDate = Timestamp.fromDate(new Date("2012-06-01T00:00:00Z"));

function userDoc(overrides = {}) {
  return {
    id: "user",
    name: "Teszt Elek",
    email: "teszt@example.com",
    role: "athlete",
    status: "pending",
    birthDate,
    childIds: [],
    parentIds: [],
    childRequests: [],
    createdAt,
    ...overrides,
  };
}

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId,
    firestore: {
      rules: readFileSync(new URL("../firestore.rules", import.meta.url), "utf8"),
    },
  });
});

after(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

async function seed(documents) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    for (const [id, data] of Object.entries(documents)) {
      await setDoc(doc(db, "users", id), data);
    }
  });
}

test("edző nem módosíthatja admin státuszát", async () => {
  await seed({
    coach1: userDoc({
      id: "coach1",
      name: "Edző",
      email: "coach@example.com",
      role: "coach",
      status: "active",
    }),
    admin1: userDoc({
      id: "admin1",
      name: "Admin",
      email: "admin@example.com",
      role: "admin",
      status: "active",
    }),
  });

  const coach = testEnv.authenticatedContext("coach1", {
    email: "coach@example.com",
  });
  await assertFails(
    updateDoc(doc(coach.firestore(), "users", "admin1"), {
      status: "rejected",
    }),
  );
});

test("jóváhagyott sportoló nem írhatja át a birthDate-et", async () => {
  await seed({
    athlete1: userDoc({
      id: "athlete1",
      email: "athlete@example.com",
      status: "active",
    }),
  });

  const athlete = testEnv.authenticatedContext("athlete1", {
    email: "athlete@example.com",
  });
  await assertFails(
    updateDoc(doc(athlete.firestore(), "users", "athlete1"), {
      birthDate: laterBirthDate,
    }),
  );
});

test("pending sportoló javíthatja a birthDate-et", async () => {
  await seed({
    athlete1: userDoc({
      id: "athlete1",
      email: "athlete@example.com",
      status: "pending",
    }),
  });

  const athlete = testEnv.authenticatedContext("athlete1", {
    email: "athlete@example.com",
  });
  await assertSucceeds(
    updateDoc(doc(athlete.firestore(), "users", "athlete1"), {
      birthDate: laterBirthDate,
    }),
  );
});

test("ismeretlen mező create-nél elutasítva", async () => {
  const uid = "new-athlete";
  const user = testEnv.authenticatedContext(uid, {
    email: "uj@example.com",
  });
  await assertFails(
    setDoc(
      doc(user.firestore(), "users", uid),
      userDoc({
        id: uid,
        email: "uj@example.com",
        photoUrl: null,
        isAdmin: true,
      }),
    ),
  );
});

test("hiányzó photoUrl mellett a saját név módosítása sikeres", async () => {
  await seed({
    athlete1: userDoc({
      id: "athlete1",
      email: "athlete@example.com",
      status: "active",
    }),
  });

  const athlete = testEnv.authenticatedContext("athlete1", {
    email: "athlete@example.com",
  });
  await assertSucceeds(
    updateDoc(doc(athlete.firestore(), "users", "athlete1"), {
      name: "Új Név",
    }),
  );
});

test("admin módosíthatja egy edző státuszát", async () => {
  await seed({
    admin1: userDoc({
      id: "admin1",
      email: "admin@example.com",
      role: "admin",
      status: "active",
    }),
    coach1: userDoc({
      id: "coach1",
      email: "coach@example.com",
      role: "coach",
      status: "active",
    }),
  });

  const admin = testEnv.authenticatedContext("admin1", {
    email: "admin@example.com",
  });
  await assertSucceeds(
    updateDoc(doc(admin.firestore(), "users", "coach1"), {
      status: "rejected",
    }),
  );
});

test("edző jóváhagyhat egy pending sportolót", async () => {
  await seed({
    coach1: userDoc({
      id: "coach1",
      email: "coach@example.com",
      role: "coach",
      status: "active",
    }),
    athlete1: userDoc({
      id: "athlete1",
      email: "athlete@example.com",
      status: "pending",
    }),
  });

  const coach = testEnv.authenticatedContext("coach1", {
    email: "coach@example.com",
  });
  await assertSucceeds(
    updateDoc(doc(coach.firestore(), "users", "athlete1"), {
      status: "active",
    }),
  );
});
