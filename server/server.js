const dns = require('dns');
// Use reliable public DNS to resolve Atlas SRV records on Windows
dns.setServers(['8.8.8.8', '8.8.4.4']);
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 5000;
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb+srv://prince:prince55833@cluster1.niqvdam.mongodb.net/Smrithi_Saathi';

// Middleware
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use((err, req, res, next) => {
  if (err instanceof SyntaxError && err.status === 400 && 'body' in err) {
    return res.status(400).json({ error: 'Malformed JSON payload' });
  }
  next();
});

// MongoDB Connection
mongoose.connect(MONGODB_URI, {
  serverSelectionTimeoutMS: 10000,
})
.then(() => console.log('Connected to MongoDB Atlas (Smrithi_Saathi)'))
.catch(err => console.error('MongoDB Connection Error:', err));

// ----------------------------------------------------
// Schemas & Models
// ----------------------------------------------------

// 1. Caretaker Schema
const CaretakerSchema = new mongoose.Schema({
  id: { type: String, required: true, unique: true },
  name: { type: String, required: true, trim: true },
  email: { type: String, default: '', trim: true, lowercase: true },
  phone: { type: String, default: '', trim: true },
  relationship: { type: String, default: 'Family Member' },
  password: { type: String, default: '' },
  createdAt: { type: Date, default: Date.now }
});

// 2. Patient / Senior Schema
const PatientSchema = new mongoose.Schema({
  id: { type: String, required: true, unique: true },
  caretakerId: { type: String, default: '' },
  name: { type: String, required: true, trim: true },
  nickname: { type: String, default: '', trim: true },
  age: { type: Number, default: 70 },
  gender: { type: String, default: 'Other' },
  condition: { type: String, default: '' },
  language: { type: String, default: 'English' },
  emergencyContact: { type: String, default: '' },
  emergencyPhone: { type: String, default: '' },
  pairingCode: { type: String, required: true, unique: true, uppercase: true, trim: true },
  notes: { type: String, default: '' },
  createdAt: { type: Date, default: Date.now }
});

// 3. Memory Schema
const MemorySchema = new mongoose.Schema({
  id: { type: String, required: true, unique: true },
  patientId: { type: String, default: '' },
  title: { type: String, required: true },
  subtitle: { type: String, default: '' },
  category: { type: String, default: 'General' },
  description: { type: String, default: '' },
  event: { type: String, default: '' },
  taggedPersons: { type: [String], default: [] },
  mediaPath: { type: String, default: null },
  isVideo: { type: Boolean, default: false },
  recallQuestion: { type: String, default: '' },
  recallAnswer: { type: String, default: '' },
  alternativeAnswers: { type: [String], default: [] },
  reminiscenceStory: { type: String, default: '' },
  createdAt: { type: Date, default: Date.now }
});

// 4. Family Member Schema
const FamilyMemberSchema = new mongoose.Schema({
  id: { type: String, required: true, unique: true },
  patientId: { type: String, default: '' },
  name: { type: String, required: true },
  relation: { type: String, required: true },
  phone: { type: String, default: '' },
  notes: { type: String, default: '' },
  createdAt: { type: Date, default: Date.now }
});

// 5. Routine Reminder Schema
const ReminderSchema = new mongoose.Schema({
  id: { type: String, required: true, unique: true },
  patientId: { type: String, default: '' },
  title: { type: String, required: true },
  subtitle: { type: String, default: '' },
  time: { type: String, required: true },
  completed: { type: Boolean, default: false },
  createdAt: { type: Date, default: Date.now }
});

const Caretaker = mongoose.model('Caretaker', CaretakerSchema);
const Patient = mongoose.model('Patient', PatientSchema);
const Memory = mongoose.model('Memory', MemorySchema);
const FamilyMember = mongoose.model('FamilyMember', FamilyMemberSchema);
const Reminder = mongoose.model('Reminder', ReminderSchema);

// ----------------------------------------------------
// Health Check Endpoint
// ----------------------------------------------------
app.get('/api/health', (req, res) => {
  const isConnected = mongoose.connection.readyState === 1;
  res.json({
    status: 'ok',
    database: 'Smrithi_Saathi',
    connected: isConnected,
    timestamp: new Date().toISOString()
  });
});

// ----------------------------------------------------
// Caretaker Authentication & Profile Endpoints
// ----------------------------------------------------
app.post('/api/caretakers/signup', async (req, res) => {
  try {
    const { name, email, phone, relationship, password } = req.body;
    if (!name || !name.trim()) {
      return res.status(400).json({ error: 'Name is required' });
    }
    const cleanEmail = (email || '').trim().toLowerCase();
    const cleanPhone = (phone || '').trim().replace(/\s+/g, '');
    const id = req.body.id || 'ct_' + Date.now();

    // Check if caretaker exists by email or phone
    let existing = null;
    if (cleanEmail) {
      existing = await Caretaker.findOne({ email: cleanEmail });
    }
    if (!existing && cleanPhone) {
      existing = await Caretaker.findOne({ phone: cleanPhone });
    }

    let caretaker;
    if (existing) {
      existing.name = name.trim();
      if (cleanEmail) existing.email = cleanEmail;
      if (cleanPhone) existing.phone = cleanPhone;
      if (relationship) existing.relationship = relationship;
      if (password) existing.password = password;
      caretaker = await existing.save();
    } else {
      caretaker = await Caretaker.create({
        id,
        name: name.trim(),
        email: cleanEmail,
        phone: cleanPhone,
        relationship: relationship || 'Family Member',
        password: password || ''
      });
    }

    res.status(201).json({
      success: true,
      caretaker: {
        id: caretaker.id,
        name: caretaker.name,
        email: caretaker.email,
        phone: caretaker.phone,
        relationship: caretaker.relationship,
        password: caretaker.password
      }
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/caretakers/login', async (req, res) => {
  try {
    const { emailOrPhone, password } = req.body;
    if (!emailOrPhone || !emailOrPhone.trim()) {
      return res.status(400).json({ error: 'Email or phone number is required' });
    }

    const input = emailOrPhone.trim();
    const cleanEmail = input.toLowerCase();
    const cleanPhone = input.replace(/[\s\-()]/g, '');

    // Search in MongoDB Atlas
    let caretaker = await Caretaker.findOne({
      $or: [
        { email: cleanEmail },
        { phone: cleanPhone },
        { phone: input }
      ]
    });

    // If demo requested, auto-provision demo caretaker in MongoDB Atlas
    if (!caretaker && (cleanEmail === 'rajesh.care@health.org' || cleanEmail.includes('demo') || cleanEmail.includes('meena'))) {
      caretaker = await Caretaker.create({
        id: 'ct_demo',
        name: 'Dr. Rajesh Kumar',
        email: 'rajesh.care@health.org',
        phone: '+91 98450 12345',
        relationship: 'Doctor / Nurse',
        password: 'care123'
      });
    }

    if (!caretaker) {
      return res.status(404).json({
        error: 'No caretaker account found with that email or phone. Please sign up first.'
      });
    }

    // Password validation if password was provided/set
    if (caretaker.password && password && caretaker.password !== password) {
      return res.status(401).json({ error: 'Incorrect password or PIN. Please try again.' });
    }

    // Fetch registered patients for this caretaker from MongoDB Atlas
    const patients = await Patient.find({
      $or: [
        { caretakerId: caretaker.id },
        { caretakerId: '' },
        { caretakerId: { $exists: false } }
      ]
    }).sort({ createdAt: -1 });

    res.json({
      success: true,
      caretaker: {
        id: caretaker.id,
        name: caretaker.name,
        email: caretaker.email,
        phone: caretaker.phone,
        relationship: caretaker.relationship,
        password: caretaker.password
      },
      patients: patients.map(p => ({
        id: p.id,
        name: p.name,
        nickname: p.nickname,
        age: p.age,
        gender: p.gender,
        condition: p.condition,
        language: p.language,
        emergencyContact: p.emergencyContact,
        emergencyPhone: p.emergencyPhone,
        pairingCode: p.pairingCode,
        notes: p.notes
      }))
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/caretakers', async (req, res) => {
  try {
    const list = await Caretaker.find().sort({ createdAt: -1 });
    res.json(list);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ----------------------------------------------------
// Patient / Senior Registration & Validation Endpoints
// ----------------------------------------------------
app.post('/api/patients', async (req, res) => {
  try {
    const data = req.body;
    if (!data.name || !data.name.trim()) {
      return res.status(400).json({ error: 'Patient name is required' });
    }
    if (!data.id) data.id = 'pt_' + Date.now();
    if (!data.pairingCode) {
      data.pairingCode = 'SAATHI-' + Math.floor(1000 + Math.random() * 9000);
    }
    data.pairingCode = data.pairingCode.trim().toUpperCase();

    const patient = await Patient.findOneAndUpdate(
      { id: data.id },
      data,
      { upsert: true, new: true }
    );

    res.status(201).json({ success: true, patient });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

app.get('/api/patients', async (req, res) => {
  try {
    const filter = {};
    if (req.query.caretakerId) {
      filter.caretakerId = req.query.caretakerId;
    }
    const patients = await Patient.find(filter).sort({ createdAt: -1 });
    res.json(patients);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/patients/validate-passkey', async (req, res) => {
  try {
    const { passKey } = req.body;
    if (!passKey || !passKey.trim()) {
      return res.status(400).json({ success: false, error: 'Pass key is required' });
    }

    const clean = passKey.trim().toUpperCase();

    // Instant Guest / Demo Senior Login
    if (clean === 'DEMO' || clean === 'GUEST') {
      let demoSenior = await Patient.findOne({ pairingCode: 'SAATHI-DEMO' });
      if (!demoSenior) {
        demoSenior = await Patient.create({
          id: 'pt_demo_senior',
          name: 'Shanti Devi',
          nickname: 'Dadi',
          age: 76,
          gender: 'Female',
          condition: 'Mild Cognitive Impairment (Early Stage)',
          language: 'Hindi & English',
          emergencyContact: 'Rajesh Kumar (Son)',
          emergencyPhone: '+91 98450 12345',
          pairingCode: 'SAATHI-DEMO',
          notes: 'Enjoys classical music, morning garden strolls, and looking at family albums.'
        });
      }
      return res.json({ success: true, patient: demoSenior });
    }

    // Lookup in MongoDB Atlas
    const searchConditions = [
      { pairingCode: clean },
      { pairingCode: 'SAATHI-' + clean },
      { id: clean }
    ];
    if (clean.startsWith('SAATHI-')) {
      searchConditions.push({ pairingCode: clean.replace('SAATHI-', '') });
    }

    const patient = await Patient.findOne({ $or: searchConditions });
    if (!patient) {
      return res.status(404).json({
        success: false,
        error: `Pass key "${passKey.trim()}" not found in database. Please verify with your caretaker or use DEMO.`
      });
    }

    res.json({ success: true, patient });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// ----------------------------------------------------
// Memories Endpoints
// ----------------------------------------------------
app.get('/api/memories', async (req, res) => {
  try {
    const filter = {};
    if (req.query.patientId) filter.patientId = req.query.patientId;
    const memories = await Memory.find(filter).sort({ createdAt: -1 });
    res.json(memories);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/memories', async (req, res) => {
  try {
    const data = req.body;
    if (!data.id) data.id = 'mem_' + Date.now();
    const memory = await Memory.findOneAndUpdate(
      { id: data.id },
      data,
      { upsert: true, new: true }
    );
    res.status(201).json(memory);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

app.delete('/api/memories/:id', async (req, res) => {
  try {
    const result = await Memory.findOneAndDelete({ id: req.params.id });
    if (!result) return res.status(404).json({ error: 'Memory not found' });
    res.json({ success: true, deleted: result });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ----------------------------------------------------
// Family Endpoints
// ----------------------------------------------------
app.get('/api/family', async (req, res) => {
  try {
    const filter = {};
    if (req.query.patientId) filter.patientId = req.query.patientId;
    const members = await FamilyMember.find(filter).sort({ createdAt: 1 });
    res.json(members);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/family', async (req, res) => {
  try {
    const data = req.body;
    if (!data.id) data.id = 'family_' + Date.now();
    const member = await FamilyMember.findOneAndUpdate(
      { id: data.id },
      data,
      { upsert: true, new: true }
    );
    res.status(201).json(member);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

app.delete('/api/family/:id', async (req, res) => {
  try {
    const result = await FamilyMember.findOneAndDelete({ id: req.params.id });
    if (!result) return res.status(404).json({ error: 'Family member not found' });
    res.json({ success: true, deleted: result });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ----------------------------------------------------
// Reminders Endpoints
// ----------------------------------------------------
app.get('/api/reminders', async (req, res) => {
  try {
    const filter = {};
    if (req.query.patientId) filter.patientId = req.query.patientId;
    const reminders = await Reminder.find(filter).sort({ createdAt: 1 });
    res.json(reminders);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/reminders', async (req, res) => {
  try {
    const data = req.body;
    if (!data.id) data.id = 'reminder_' + Date.now();
    const reminder = await Reminder.findOneAndUpdate(
      { id: data.id },
      data,
      { upsert: true, new: true }
    );
    res.status(201).json(reminder);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

app.put('/api/reminders/:id', async (req, res) => {
  try {
    const reminder = await Reminder.findOneAndUpdate(
      { id: req.params.id },
      req.body,
      { new: true }
    );
    if (!reminder) return res.status(404).json({ error: 'Reminder not found' });
    res.json(reminder);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

app.delete('/api/reminders/:id', async (req, res) => {
  try {
    const result = await Reminder.findOneAndDelete({ id: req.params.id });
    if (!result) return res.status(404).json({ error: 'Reminder not found' });
    res.json({ success: true, deleted: result });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ----------------------------------------------------
// Clean All Data Endpoint
// ----------------------------------------------------
app.delete('/api/cleanup/all', async (req, res) => {
  try {
    const m = await Memory.deleteMany({});
    const f = await FamilyMember.deleteMany({});
    const r = await Reminder.deleteMany({});
    const p = await Patient.deleteMany({});
    const c = await Caretaker.deleteMany({});
    res.json({
      success: true,
      message: 'All collections cleaned from MongoDB Atlas.',
      deletedCounts: {
        memories: m.deletedCount,
        family: f.deletedCount,
        reminders: r.deletedCount,
        patients: p.deletedCount,
        caretakers: c.deletedCount
      }
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.listen(PORT, () => {
  console.log(`Smrithi Saathi Backend API running on http://localhost:${PORT}`);
});
