import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import request from 'supertest';
import express from 'express';
import monk from 'monk';
import cors from 'cors';


const mockUsers = [];
const db = {
  get: () => ({
    find: async () => [...mockUsers],
    insert: async (doc) => {
      mockUsers.push({ ...doc, _id: String(mockUsers.length + 1), createdAt: new Date() });
      return mockUsers[mockUsers.length - 1];
    },
    remove: async () => {
      mockUsers.length = 0;
    }
  }),
  close: async () => {}
};

const users = db.get('users');

const app = express();
app.use(cors());
app.use(express.json());

app.get('/api/users', async (req, res) => {
  const allUsers = await users.find({});
  res.json(allUsers);
});

app.post('/api/users', async (req, res) => {
  const { name, email } = req.body;
  const user = await users.insert({ name, email });
  res.status(201).json(user);
});

beforeAll(async () => {
  await users.remove({});
});

afterAll(async () => {
  await db.close();
});

describe('Users API', () => {
  it('should create a new user', async () => {
    const res = await request(app)
      .post('/api/users')
      .send({ name: 'Test User', email: 'test@example.com' });
    expect(res.statusCode).toBe(201);
    expect(res.body.name).toBe('Test User');
    expect(res.body.email).toBe('test@example.com');
  });

  it('should get all users', async () => {
    const res = await request(app).get('/api/users');
    expect(res.statusCode).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
    expect(res.body.length).toBeGreaterThan(0);
  });
});
