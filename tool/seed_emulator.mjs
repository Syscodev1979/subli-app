// Mintaadat a HELYI emulátorba. Felhőbe nem ír.
// Minden minta fiók jelszava: Subli2026!
import { createRequire } from 'node:module';

const requireFromFunctions = createRequire(
  new URL('../functions/package.json', import.meta.url),
);
const { initializeApp } = requireFromFunctions('firebase-admin/app');
const { getAuth } = requireFromFunctions('firebase-admin/auth');
const { getFirestore, Timestamp } = requireFromFunctions(
  'firebase-admin/firestore',
);
const { nameKeywords } = requireFromFunctions('./conversation-logic.js');

process.env.FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9099';
process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080';
process.env.FIREBASE_STORAGE_EMULATOR_HOST = '127.0.0.1:9199';

const password = 'Subli2026!';

const users = [
  {
    uid: 'seed-admin',
    email: 'info@sarosigyorgy.hu',
    name: 'Sárosi György',
    role: 'admin',
    status: 'active',
    birthDate: '1985-04-12',
    beltRank: 'competitor',
    groupIds: ['group-tura'],
  },
  {
    uid: 'seed-anna',
    email: 'anna.kovacs@example.com',
    name: 'Kovács Anna',
    role: 'member',
    status: 'active',
    birthDate: '1990-06-03',
    beltRank: 'advanced',
    groupIds: ['group-dijugratok', 'group-haladok'],
  },
  {
    uid: 'seed-peter',
    email: 'peter.nagy@example.com',
    name: 'Nagy Péter',
    role: 'member',
    status: 'active',
    birthDate: '1998-02-18',
    beltRank: 'beginner',
    groupIds: ['group-kezdok'],
  },
  {
    uid: 'seed-eszter',
    email: 'eszter.szabo@example.com',
    name: 'Szabó Eszter',
    role: 'member',
    status: 'active',
    birthDate: '1996-11-21',
    beltRank: 'competitor',
    groupIds: ['group-tura'],
  },
  {
    uid: 'seed-gabor',
    email: 'gabor.toth@example.com',
    name: 'Tóth Gábor',
    role: 'member',
    status: 'pending',
    birthDate: '2001-09-09',
    beltRank: 'beginner',
    groupIds: [],
  },
];

const groups = [
  ['group-kezdok', 'Kezdők', '#2E7D32', 'Az első lépések a nyeregben.'],
  ['group-haladok', 'Haladók', '#1F6FEB', 'Önálló munka a pályán.'],
  ['group-dijugratok', 'Díjugratók', '#D7262B', 'Ugrófeladatok és pályaépítés.'],
  ['group-tura', 'Túralovasok', '#C9A227', 'Hétvégi tereplovaglás.'],
];

function at(iso) {
  return Timestamp.fromDate(new Date(iso));
}

function userDoc(user) {
  return {
    id: user.uid,
    name: user.name,
    email: user.email,
    role: user.role,
    status: user.status,
    birthDate: at(`${user.birthDate}T00:00:00.000Z`),
    photoUrl: null,
    childIds: [],
    parentIds: [],
    childRequests: [],
    groupIds: user.groupIds,
    beltRank: user.beltRank,
    createdAt: at('2026-10-01T08:00:00.000Z'),
  };
}

function memberDoc(user) {
  return {
    name: user.name,
    photoUrl: null,
    role: user.role,
    isMinor: false,
    parentIds: [],
    searchKeywords: nameKeywords(user.name),
    status: 'active',
    beltRank: user.beltRank,
    groupIds: user.groupIds,
  };
}

async function waitForAuth() {
  const url = 'http://127.0.0.1:9099/';
  for (let attempt = 0; attempt < 60; attempt += 1) {
    try {
      const response = await fetch(url);
      if (response.ok || response.status < 500) return;
    } catch {
      // Az emulátor még indul.
    }
    await new Promise((resolve) => setTimeout(resolve, 1000));
  }
  throw new Error('Az Auth emulátor nem elérhető a 9099-es porton.');
}

async function upsertUser(auth, user) {
  try {
    await auth.createUser({
      uid: user.uid,
      email: user.email,
      password,
      emailVerified: true,
      displayName: user.name,
    });
  } catch (error) {
    if (error.code !== 'auth/uid-already-exists') throw error;
    await auth.updateUser(user.uid, {
      email: user.email,
      password,
      emailVerified: true,
      displayName: user.name,
    });
  }
}

async function main() {
  await waitForAuth();
  initializeApp({ projectId: 'demo-subli' });
  const auth = getAuth();
  const db = getFirestore();

  for (const user of users) {
    await upsertUser(auth, user);
    await db.collection('users').doc(user.uid).set(userDoc(user));
    const member = db.collection('members').doc(user.uid);
    if (user.status === 'active') {
      await member.set(memberDoc(user));
    } else {
      await member.delete();
    }
  }

  for (const [id, name, color, description] of groups) {
    await db.collection('groups').doc(id).set({
      name,
      color,
      description,
      createdAt: at('2026-10-01T08:00:00.000Z'),
    });
  }

  const posts = [
    {
      id: 'post-kozlemeny',
      authorId: 'seed-admin',
      authorName: 'Sárosi György',
      text: 'Szombaton a fedeles pálya 9-től a díjugratóké. A kezdők 11-kor lovagolnak.',
      createdAt: '2026-11-03T07:30:00.000Z',
      pinned: true,
      category: 'announcement',
    },
    {
      id: 'post-hir',
      authorId: 'seed-anna',
      authorName: 'Kovács Anna',
      text: 'Megérkezett a téli takarmány. A lovak adagja a táblán olvasható.',
      createdAt: '2026-11-02T16:00:00.000Z',
      pinned: false,
      category: 'post',
    },
    {
      id: 'post-esemeny',
      authorId: 'seed-anna',
      authorName: 'Kovács Anna',
      text: 'Nyílt ház a lovardában: bemutató lovaglás és istállóbejárás.',
      createdAt: '2026-11-01T10:00:00.000Z',
      pinned: false,
      category: 'event',
      eventStartsAt: '2026-11-15T09:00:00.000Z',
      eventEndsAt: '2026-11-15T12:00:00.000Z',
    },
    {
      id: 'post-edzes',
      authorId: 'seed-anna',
      authorName: 'Kovács Anna',
      text: 'A kezdő csoport szerdán ügetésből galoppváltást gyakorol.',
      createdAt: '2026-11-01T18:00:00.000Z',
      pinned: false,
      category: 'post',
    },
    {
      id: 'post-lovaink',
      authorId: 'seed-eszter',
      authorName: 'Szabó Eszter',
      text: 'Borsó szépen ment a tegnapi terepen. Jövő héten ő viszi a túrát.',
      createdAt: '2026-10-30T15:00:00.000Z',
      pinned: false,
      category: 'horses',
    },
  ];

  for (const post of posts) {
    await db.collection('posts').doc(post.id).set({
      authorId: post.authorId,
      authorName: post.authorName,
      authorPhotoUrl: null,
      text: post.text,
      createdAt: at(post.createdAt),
      updatedAt: at(post.createdAt),
      pinned: post.pinned,
      category: post.category,
      searchKeywords: post.text.toLowerCase().split(/\s+/).slice(0, 12),
      media: [],
      audience: ['all'],
      ...(post.eventStartsAt
        ? {
            eventStartsAt: at(post.eventStartsAt),
            eventEndsAt: at(post.eventEndsAt),
          }
        : {}),
    });
  }

  await db
    .collection('posts')
    .doc('post-kozlemeny')
    .collection('reactions')
    .doc('seed-anna')
    .set({
      userName: 'Kovács Anna',
      type: 'horse',
      createdAt: at('2026-11-03T08:00:00.000Z'),
    });
  await db
    .collection('posts')
    .doc('post-lovaink')
    .collection('reactions')
    .doc('seed-peter')
    .set({
      userName: 'Nagy Péter',
      type: 'like',
      createdAt: at('2026-10-30T16:00:00.000Z'),
    });
  await db
    .collection('posts')
    .doc('post-hir')
    .collection('comments')
    .doc('comment-peter')
    .set({
      authorId: 'seed-peter',
      authorName: 'Nagy Péter',
      authorPhotoUrl: null,
      text: 'A zabos zsákot a jobb oldali kamrába tettük.',
      createdAt: at('2026-11-02T17:10:00.000Z'),
    });
  await db
    .collection('posts')
    .doc('post-hir')
    .collection('comments')
    .doc('comment-eszter')
    .set({
      authorId: 'seed-eszter',
      authorName: 'Szabó Eszter',
      authorPhotoUrl: null,
      text: 'Borsó adagját megemelem egy marékkal.',
      createdAt: at('2026-11-02T17:40:00.000Z'),
    });

  const oldGroup = db.collection('conversations').doc('conv-istallo');
  const oldMessages = await oldGroup.collection('messages').listDocuments();
  for (const ref of oldMessages) await ref.delete();
  await oldGroup.delete();

  const directs = [
    {
      id: 'conv-admin-anna',
      memberIds: ['seed-admin', 'seed-anna'],
      senderId: 'seed-admin',
      text: 'Szia Anna, üdv a közösségben!',
      createdAt: '2026-11-03T08:40:00.000Z',
    },
    {
      id: 'conv-admin-peter',
      memberIds: ['seed-admin', 'seed-peter'],
      senderId: 'seed-admin',
      text: 'Szia Péter, mikor tudsz jönni edzésre?',
      createdAt: '2026-11-03T09:15:00.000Z',
    },
  ];
  for (const item of directs) {
    const createdAt = at(item.createdAt);
    await db.collection('conversations').doc(item.id).set({
      memberIds: item.memberIds,
      type: 'direct',
      createdAt,
      updatedAt: createdAt,
      lastReadAt: {},
      hasMinor: false,
      guardianIds: [],
      lastMessage: {
        text: item.text,
        senderId: item.senderId,
        createdAt,
      },
    });
    await db
      .collection('conversations')
      .doc(item.id)
      .collection('messages')
      .doc('msg-1')
      .set({
        senderId: item.senderId,
        text: item.text,
        createdAt,
        deleted: false,
      });
  }

  await db.collection('config').doc('app').set({
    minVersion: '0.5.0',
    latestVersion: '0.5.0',
  });

  console.log('Mintaadat kész: 5 fiók, 4 csoport, 5 bejegyzés, 2 beszélgetés.');
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
