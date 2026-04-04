require('dotenv').config();
const { expect } = require('chai');
const request = require('supertest');
const app = require('../src/app');
const mongoose = require('mongoose');
const { mockingoose } = require('mockingoose');
const jwt = require('jsonwebtoken');
const User = require('../src/models/User');
const TeacherProfile = require('../src/models/TeacherProfile');

const JWT_SECRET = process.env.JWT_SECRET || 'supersecretjwtkey';

// Valid MongoDB ObjectIds
const ADMIN_ID = '507f1f77bcf86cd799439016';
const PENDING_PROFILE_ID = '507f1f77bcf86cd799439011';
const PENDING_USER_ID = '507f1f77bcf86cd799439012';
const ACTIVE_PROFILE_ID = '507f1f77bcf86cd799439013';
const ACTIVE_USER_ID = '507f1f77bcf86cd799439014';
const STUDENT_USER_ID = '507f1f77bcf86cd799439015';

describe('Admin API Endpoints', () => {
    let adminToken;
    let regularUserToken;
    let pendingTeacherProfile;
    let activeTeacherProfile;
    let studentUser;

    before(() => {
        // Generate tokens
        adminToken = jwt.sign({ userId: ADMIN_ID, role: 'admin' }, JWT_SECRET, { expiresIn: '1h' });
        regularUserToken = jwt.sign({ userId: STUDENT_USER_ID, role: 'student' }, JWT_SECRET, { expiresIn: '1h' });

        pendingTeacherProfile = {
            _id: PENDING_PROFILE_ID,
            userId: PENDING_USER_ID,
            title: 'Pending Teacher',
            bio: 'Pending bio',
            status: 'pending',
            isVerified: false,
            experienceYears: 2,
            price: 40,
            toObject: function() { return { ...this }; }
        };

        activeTeacherProfile = {
            _id: ACTIVE_PROFILE_ID,
            userId: ACTIVE_USER_ID,
            title: 'Active Teacher',
            bio: 'Active bio',
            status: 'active',
            isVerified: true,
            experienceYears: 5,
            price: 60,
            toObject: function() { return { ...this }; }
        };

        studentUser = {
            _id: STUDENT_USER_ID,
            name: 'Student User',
            email: 'student@example.com',
            role: 'student',
            toObject: function() { return { ...this }; }
        };
    });

    beforeEach(() => {
        // Default mocks
        mockingoose(User).toReturn({
            _id: ADMIN_ID,
            name: 'Admin User',
            role: 'admin'
        }, 'findOne'); 

        mockingoose(TeacherProfile).toReturn(pendingTeacherProfile, 'findOne');
        mockingoose(TeacherProfile).toReturn(pendingTeacherProfile, 'findById');
        mockingoose(TeacherProfile).toReturn(activeTeacherProfile, 'findOneAndUpdate');
        mockingoose(TeacherProfile).toReturn([pendingTeacherProfile], 'find'); 
        mockingoose(User).toReturn(studentUser, 'findById');
    });

    afterEach(() => {
        mockingoose.resetAll();
    });

    describe('Admin Teacher Management', () => {
        it('should allow admin to get a list of teachers', async () => {
            mockingoose(TeacherProfile).toReturn([
                {
                    ...pendingTeacherProfile,
                    userId: { _id: PENDING_USER_ID, name: 'Pending User', email: 'pending@example.com' }
                }
            ], 'find');

            const res = await request(app)
                .get('/api/admin/teachers')
                .set('Authorization', `Bearer ${adminToken}`);

            expect(res.statusCode).to.equal(200);
            expect(Array.isArray(res.body)).to.be.true;
            expect(res.body).to.have.lengthOf(1);
            expect(res.body[0].status).to.equal('pending');
        });

        it('should prevent non-admin from getting a list of teachers', async () => {
            const res = await request(app)
                .get('/api/admin/teachers')
                .set('Authorization', `Bearer ${regularUserToken}`);

            expect(res.statusCode).to.equal(403);
        });

        it("should allow admin to get a single teacher's details", async () => {
            mockingoose(TeacherProfile).toReturn({
                ...pendingTeacherProfile,
                userId: { _id: PENDING_USER_ID, name: 'Pending User', email: 'pending@example.com' }
            }, 'findOne');

            const res = await request(app)
                .get(`/api/admin/teachers/${PENDING_PROFILE_ID}`)
                .set('Authorization', `Bearer ${adminToken}`);

            expect(res.statusCode).to.equal(200);
            expect(res.body._id.toString()).to.equal(PENDING_PROFILE_ID);
        });

        it('should allow admin to approve a teacher', async () => {
            mockingoose(TeacherProfile).toReturn({
                ...pendingTeacherProfile,
                status: 'active',
                isVerified: true
            }, 'findOneAndUpdate');

            const res = await request(app)
                .put(`/api/admin/teachers/${PENDING_PROFILE_ID}/status`)
                .set('Authorization', `Bearer ${adminToken}`)
                .send({ status: 'approved' });

            expect(res.statusCode).to.equal(200);
            expect(res.body.status).to.equal('active');
            expect(res.body.isVerified).to.be.true;
        });

        it('should allow admin to get dashboard metrics', async () => {
            mockingoose(User).toReturn(10, 'countDocuments'); 
            mockingoose(TeacherProfile).toReturn(5, 'countDocuments'); 

            const res = await request(app)
                .get('/api/admin/dashboard/metrics')
                .set('Authorization', `Bearer ${adminToken}`);

            expect(res.statusCode).to.equal(200);
            expect(res.body.totalTeachers).to.equal(10);
            expect(res.body.pendingTeachers).to.equal(5);
        });
    });

    describe('Student Details Endpoint', () => {
        it('should allow admin to get student details', async () => {
            mockingoose(User).toReturn(studentUser, 'findOne'); // findById uses findOne under the hood in mockingoose

            const res = await request(app)
                .get(`/api/admin/students/${STUDENT_USER_ID}`)
                .set('Authorization', `Bearer ${adminToken}`);

            expect(res.statusCode).to.equal(200);
            expect(res.body._id.toString()).to.equal(STUDENT_USER_ID);
            expect(res.body.role).to.equal('student');
        });

        it('should return 404 if student not found or not a student', async () => {
            mockingoose(User).toReturn(null, 'findOne');
            
            const res = await request(app)
                .get(`/api/admin/students/${PENDING_USER_ID}`)
                .set('Authorization', `Bearer ${adminToken}`);

            expect(res.statusCode).to.equal(404);
        });
    });
});
