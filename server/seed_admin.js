const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const User = require('./src/models/User');
require('dotenv').config();

const createAdmin = async () => {
    try {
        await mongoose.connect(process.env.MONGO_URI);
        console.log('Connected to MongoDB.');

        const email = 'super@emulearn.com';
        const hashedPassword = await bcrypt.hash('super', 10);

        const adminExists = await User.findOne({ email });
        if (adminExists) {
            console.log('Admin already exists.');
        } else {
            const admin = new User({
                name: 'Super Admin',
                email: email,
                password: hashedPassword,
                role: 'admin'
            });
            await admin.save();
            console.log('Super Admin created successfully!');
            console.log('Email: super@emulearn.com');
            console.log('Password: super');
        }
    } catch (err) {
        console.error('Error creating admin:', err);
    } finally {
        await mongoose.connection.close();
    }
};

createAdmin();
