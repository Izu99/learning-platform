require('dotenv').config();
const { expect } = require('chai');
const request = require('supertest');
const app = require('../src/app');
const { mockingoose } = require('mockingoose');
const jwt = require('jsonwebtoken');
const User = require('../src/models/User');
const TeacherProfile = require('../src/models/TeacherProfile');
const Booking = require('../models/Booking');

const JWT_SECRET = process.env.JWT_SECRET || 'supersecretjwtkey';
const TEACHER_USER_ID = '507f1f77bcf86cd799439014';
const TEACHER_PROFILE_ID = '507f1f77bcf86cd799439011';

describe('Teacher API', () => {
    let teacherToken;
    let mockProfileData;

    before(() => {
        teacherToken = jwt.sign({ id: TEACHER_USER_ID, role: 'teacher' }, JWT_SECRET);
        
        mockProfileData = {
            _id: TEACHER_PROFILE_ID,
            userId: TEACHER_USER_ID,
            title: 'Math Pro',
            status: 'active',
            bio: 'Bio here',
            availability: [
                {
                    date: '2026-04-01',
                    slots: [{ start: '10:00', end: '12:00', available: true }]
                }
            ]
        };
    });

    beforeEach(() => {
        // Return a function that creates a new document to ensure it has mongoose methods
        mockingoose(TeacherProfile).toReturn((query) => {
            return new TeacherProfile(mockProfileData);
        }, 'findOne');

        mockingoose(TeacherProfile).toReturn((query) => {
            return new TeacherProfile(mockProfileData);
        }, 'findById');

        mockingoose(TeacherProfile).toReturn([new TeacherProfile(mockProfileData)], 'find');
        
        mockingoose(TeacherProfile).toReturn(new TeacherProfile(mockProfileData), 'findOneAndUpdate');

        // Mock Booking for available-slots
        mockingoose(Booking).toReturn([], 'find');
    });

    afterEach(() => {
        mockingoose.resetAll();
    });

    describe('GET /api/teachers', () => {
        it('should list all teachers', async () => {
            const res = await request(app).get('/api/teachers');
            expect(res.statusCode).to.equal(200);
            expect(Array.isArray(res.body)).to.be.true;
        });
    });

    describe('GET /api/teachers/profile/:userId', () => {
        it('should return teacher profile for a valid userId', async () => {
            const res = await request(app).get(`/api/teachers/profile/${TEACHER_USER_ID}`);
            expect(res.statusCode).to.equal(200);
            expect(res.body.title).to.equal('Math Pro');
        });

        it('should return 404 if profile not found', async () => {
            mockingoose(TeacherProfile).toReturn(null, 'findOne');
            const res = await request(app).get(`/api/teachers/profile/nonexistent`);
            expect(res.statusCode).to.equal(404);
        });
    });

    describe('POST /api/teachers/profile', () => {
        it('should create or update profile when authenticated', async () => {
            const res = await request(app)
                .post('/api/teachers/profile')
                .set('Authorization', `Bearer ${teacherToken}`)
                .send({ title: 'New Title', bio: 'New bio' });

            expect(res.statusCode).to.equal(200);
        });
    });

    describe('GET /api/teachers/:teacherId/available-slots', () => {
        it('should return available slots for a teacher', async () => {
            const res = await request(app)
                .get(`/api/teachers/${TEACHER_USER_ID}/available-slots`)
                .query({ date: '2026-04-01' });

            expect(res.statusCode).to.equal(200);
            expect(Array.isArray(res.body)).to.be.true;
            expect(res.body.length).to.be.at.least(1);
        });
    });
});
