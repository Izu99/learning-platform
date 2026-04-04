require('dotenv').config();
const { expect } = require('chai');
const request = require('supertest');
const app = require('../src/app');
const { mockingoose } = require('mockingoose');
const jwt = require('jsonwebtoken');
const User = require('../src/models/User');
const TeacherProfile = require('../src/models/TeacherProfile');

const JWT_SECRET = process.env.JWT_SECRET || 'supersecretjwtkey';
const USER_ID = '507f1f77bcf86cd799439015';

describe('Authentication API', () => {
    afterEach(() => {
        mockingoose.resetAll();
    });

    describe('POST /api/auth/register', () => {
        it('should register a new student successfully', async () => {
            const userData = {
                name: 'Test Student',
                email: 'student@test.com',
                password: 'password123',
                role: 'student'
            };

            mockingoose(User).toReturn({ ...userData, _id: USER_ID }, 'save');

            const res = await request(app)
                .post('/api/auth/register')
                .send(userData);

            expect(res.statusCode).to.equal(201);
            expect(res.body).to.have.property('token');
            expect(res.body.user.email).to.equal(userData.email);
        });
    });

    describe('POST /api/auth/login', () => {
        it('should login successfully with correct credentials', async () => {
            const userDoc = {
                _id: USER_ID,
                email: 'student@test.com',
                password: 'hashedpassword',
                role: 'student'
            };

            // Use toReturn function to simulate instance method
            mockingoose(User).toReturn((query) => {
                const doc = new User(userDoc);
                doc.comparePassword = async () => true;
                return doc;
            }, 'findOne');

            const res = await request(app)
                .post('/api/auth/login')
                .send({ email: 'student@test.com', password: 'password123' });

            expect(res.statusCode).to.equal(200);
            expect(res.body).to.have.property('token');
        });
    });

    describe('POST /api/auth/preferences', () => {
        it('should update user preferences when authenticated', async () => {
            const token = jwt.sign({ id: USER_ID, role: 'student' }, JWT_SECRET);
            const preferences = { interests: ['coding'], level: 'Intermediate' };

            mockingoose(User).toReturn({ _id: USER_ID, ...preferences }, 'findOneAndUpdate');

            const res = await request(app)
                .post('/api/auth/preferences')
                .set('Authorization', `Bearer ${token}`)
                .send(preferences);

            expect(res.statusCode).to.equal(200);
            expect(res.body.interests).to.include('coding');
        });
    });
});
