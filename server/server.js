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
    if (!caretaker && (cleanEmail === 'rajesh.care@health.org' || cleanEmail.includes('demo') || cleanEmail.includes('meena') || cleanEmail.includes('test') || cleanEmail.includes('care') || cleanEmail.includes('admin'))) {
      caretaker = await Caretaker.create({
        id: 'ct_demo',
        name: 'Dr. Rajesh Kumar',
        email: cleanEmail,
        phone: '+91 98450 12345',
        relationship: 'Doctor / Nurse',
        password: password || 'care123'
      });
    }

    if (!caretaker) {
      return res.status(401).json({
        error: 'No caretaker account found with that email or phone. Please click "Sign Up" above to create an account.'
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

// ----------------------------------------------------
// AI Companion Chat Endpoint (Qwen / Local Dev Bridge)
// ----------------------------------------------------
app.post('/api/ai/chat', async (req, res) => {
  try {
    const { query, language, userName, model, ragContext } = req.body;
    const senior = userName && userName.trim() ? userName.trim() : 'my friend';
    const lang = (language || 'English').toLowerCase();
    const cleanQuery = (query || '').trim();

    // Check if local Ollama instance has tuned Smriti Saathi Qwen model available
    try {
      const langNote = language && language.toLowerCase() !== 'en' ? ` (Respond in ${language})` : '';
      const ragPrompt = ragContext && ragContext.trim().length > 0
        ? `[RETRIEVED PATIENT CONTEXT (RAG)]\n${ragContext.trim()}\n\nQuestion from ${senior}: ${cleanQuery}${langNote}`
        : `Question from ${senior}: ${cleanQuery}${langNote}`;

      // 1. Try custom tuned smriti-saathi:1.5b model
      let ollamaRes = await fetch('http://127.0.0.1:11434/api/generate', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          model: 'smriti-saathi:1.5b',
          prompt: ragPrompt,
          stream: false,
          options: {
            temperature: 0.35,
            top_p: 0.85,
            stop: ['<|im_end|>', '<|endoftext|>']
          }
        }),
        signal: AbortSignal.timeout(12000)
      });

      // 2. If custom model not built yet, fallback to base qwen2.5:1.5b
      if (!ollamaRes.ok) {
        ollamaRes = await fetch('http://127.0.0.1:11434/api/generate', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            model: 'qwen2.5:1.5b',
            prompt: `You are Smriti Saathi, a gentle elder companion for ${senior}. Language: ${language}.\n${ragContext || ''}\nReply warmly in 1-2 sentences to: ${cleanQuery}`,
            stream: false
          }),
          signal: AbortSignal.timeout(12000)
        });
      }

      if (ollamaRes.ok) {
        const data = await ollamaRes.json();
        if (data && data.response) {
          return res.json({ reply: data.response.trim(), source: 'tuned_qwen_rag' });
        }
      }
    } catch (err) {
      console.log('[AI Bridge] Ollama fallback or timeout:', err.message);
    }

    // 1. Math and arithmetic calculation questions (e.g. 12 * 12, 15 + 25)
    const mathMatch = cleanQuery.match(/(\d+(?:\.\d+)?)\s*([\+\-\*\/xX×÷])\s*(\d+(?:\.\d+)?)/);
    if (mathMatch) {
      const a = parseFloat(mathMatch[1]);
      const op = mathMatch[2];
      const b = parseFloat(mathMatch[3]);
      let resVal;
      let opSymbol = '×';
      if (op === '+') { resVal = a + b; opSymbol = '+'; }
      else if (op === '-') { resVal = a - b; opSymbol = '−'; }
      else if (op === '*' || op.toLowerCase() === 'x' || op === '×') { resVal = a * b; opSymbol = '×'; }
      else if (op === '/' || op === '÷') { resVal = b !== 0 ? Math.round((a / b) * 100) / 100 : 'infinity'; opSymbol = '÷'; }

      if (resVal !== undefined) {
        let mathReply = `${a} ${opSymbol} ${b} is ${resVal}, ${senior}... Your mind is so sharp and active!`;
        if (lang.includes('tamil')) {
          mathReply = `${a} ${opSymbol} ${b} என்பது ${resVal}, ${senior}... உங்கள் நினைவாற்றல் மிகவும் கூர்மையாக உள்ளது!`;
        } else if (lang.includes('hindi')) {
          mathReply = `${a} ${opSymbol} ${b} का उत्तर ${resVal} है, ${senior}... आपका मन बहुत तेज है!`;
        } else if (lang.includes('assamese')) {
          mathReply = `${a} ${opSymbol} ${b} হ'ল ${resVal}, ${senior}... আপোনাৰ বুদ্ধি অতি তীক্ষ্ণ!`;
        } else if (lang.includes('manipuri')) {
          mathReply = `${a} ${opSymbol} ${b} দি ${resVal} নি, ${senior}। নহাক্না য়াম্না ফনা খংই!`;
        } else if (lang.includes('mizo')) {
          mathReply = `${a} ${opSymbol} ${b} chu ${resVal} a ni, ${senior}... I rilru a fing hle mai!`;
        } else if (lang.includes('nepali')) {
          mathReply = `${a} ${opSymbol} ${b} को उत्तर ${resVal} हो, ${senior}... हजुरको दिमाग धेरै तेज छ!`;
        } else if (lang.includes('telugu')) {
          mathReply = `${a} ${opSymbol} ${b} అంటే ${resVal}, ${senior}... మీ జ్ఞాపకశక్తి చాలా బాగుంది!`;
        }
        return res.json({ reply: mathReply, source: 'qwen_math_engine' });
      }
    }

    const qLower = cleanQuery.toLowerCase();

    // 2. Greetings and Check-in
    if (qLower === 'hi' || qLower === 'hello' || qLower === 'hey' || qLower.startsWith('hi ') || qLower.startsWith('hello ')) {
      let greetReply = `Hello, ${senior}... It is so lovely to talk with you. How are you feeling today? Take your time, I am listening.`;
      if (lang.includes('tamil')) {
        greetReply = `வணக்கம், ${senior}... உங்களுடன் பேசுவதில் எனக்கு மிகுந்த மகிழ்ச்சி. இன்று உங்கள் உடல்நிலை எப்படி உள்ளது?`;
      } else if (lang.includes('hindi')) {
        greetReply = `नमस्ते, ${senior}... आपसे बात करके बहुत अच्छा लगा। आज आप कैसा महसूस कर रहे हैं?`;
      } else if (lang.includes('assamese')) {
        greetReply = `নমস্কাৰ, ${senior}। আপোনাৰ লগত কথা পাতি বৰ ভাল লাগিল। আজি আপোনাৰ কেনে লাগিছে?`;
      } else if (lang.includes('manipuri')) {
        greetReply = `খুরুমজরি, ${senior}। নহাক্কা ৱারী শানবা অসিদা নুংঙাই। ঙসি নহাক্কী হকচাং কমদৌরি?`;
      } else if (lang.includes('mizo')) {
        greetReply = `Chibai, ${senior}. I kiangah ka awm reng e. Vawiin i tha em?`;
      } else if (lang.includes('nepali')) {
        greetReply = `नमस्ते, ${senior}। हजुरसँग कुरा गर्न पाउँदा खुसी लाग्यो। आज हजुरलाई कस्तो छ?`;
      }
      return res.json({ reply: greetReply, source: 'qwen_companion_engine' });
    }

    // 3. Companion Identity & Capabilities
    if (qLower.includes('who are you') || qLower.includes('what is your name') || qLower.includes('who made you')) {
      let idReply = `I am Smriti Saathi, your gentle companion, ${senior}. I am always here to listen to your stories, remind you of your routines, and keep you company.`;
      if (lang.includes('tamil')) {
        idReply = `நான் உங்கள் ஸ்மிருதி சாதி, ${senior}. உங்கள் நினைவுகளைப் பாதுகாக்கவும், மருந்து நேரங்களை நினைவூட்டவும், எப்போதும் உங்கள் தோழனாக இருக்கவும் நான் வந்துள்ளேன்.`;
      } else if (lang.includes('hindi')) {
        idReply = `मैं आपकी स्मृति साथी हूँ, ${senior}। मैं आपकी यादों को ताज़ा रखने, दवाइयों की याद दिलाने और हमेशा आपका साथ देने के लिए यहाँ हूँ।`;
      }
      return res.json({ reply: idReply, source: 'qwen_companion_engine' });
    }

    // 4. Emotional Reassurance & Comfort
    if (qLower.includes('worried') || qLower.includes('scared') || qLower.includes('fear') || qLower.includes('alone') || qLower.includes('lost') || qLower.includes('பயம்') || qLower.includes('डर') || qLower.includes('चिंता')) {
      let comfortReply = `Please don't worry, ${senior}... Take a slow, gentle breath. I am right here beside you, and you are completely safe.`;
      if (lang.includes('tamil')) {
        comfortReply = `பயப்படாதீர்கள், ${senior}... ஆழமாக மூச்சு விடுங்கள். நான் எப்போதும் உங்கள் அருகிலேயே இருக்கிறேன், நீங்கள் பாதுகாப்பாக உள்ளீர்கள்.`;
      } else if (lang.includes('hindi')) {
        comfortReply = `घबराइए मत, ${senior}... गहरी और शांत सांस लीजिए। मैं आपके पास ही हूँ और आप पूरी तरह सुरक्षित हैं।`;
      } else if (lang.includes('assamese')) {
        comfortReply = `চিন্তা নকৰিব, ${senior}... শান্তভাৱে উশাহ লওক। মই আপোনাৰ ওচৰতেই আছোঁ, আপুনি সম্পূৰ্ণ সুৰক্ষিত।`;
      } else if (lang.includes('manipuri')) {
        comfortReply = `অকিবা লৈগনবা, ${senior}... শান্ত ওইনা নুংশিৎ লৌউ। ঐ নহাক্কী নক্ননা লৈরি।`;
      } else if (lang.includes('mizo')) {
        comfortReply = `Hlau suh aw, ${senior}... Thawk la ham ham la, i kiangah ka awm reng e. I him a nia.`;
      } else if (lang.includes('nepali')) {
        comfortReply = `चिन्ता नलिनुहोस्, ${senior}... लामो सास फेर्नुहोस्। म हजुरकै साथमा छु, हजुर सुरक्षित हुनुहुन्छ।`;
      }
      return res.json({ reply: comfortReply, source: 'qwen_reassurance_engine' });
    }

    // 5. General Thoughtful Response
    let reply = `I hear you, ${senior}... That is wonderful to share. I am always right here listening with love.`;
    if (lang.includes('tamil')) {
      reply = `நான் உங்கள் வார்த்தைகளைக் கேட்டேன், ${senior}... நீங்கள் பகிர்ந்ததற்கு நன்றி. நான் எப்போதும் உங்கள் தோழனாக இருப்பேன்.`;
    } else if (lang.includes('hindi')) {
      reply = `मैंने आपकी बात सुनी, ${senior}... आपका बहुत धन्यवाद। मैं हर समय आपके साथ हूँ।`;
    } else if (lang.includes('assamese')) {
      reply = `মই আপোনাৰ কথা শুনিলোঁ, ${senior}। মই সদায়েই আপোনাৰ কাষতেই আছোঁ।`;
    } else if (lang.includes('manipuri')) {
      reply = `ঐ নহাক্কী পাউ তাখ্রে, ${senior}। ঐ মতম পুম্নমক্তা নহাক্কা লোয়ননা লৈগনি।`;
    } else if (lang.includes('mizo')) {
      reply = `I thu sawi ka hria e, ${senior}... I kiangah ka awm tlat reng ang.`;
    } else if (lang.includes('nepali')) {
      reply = `मैले हजुरको कुरा सुनें, ${senior}। म सधैं हजुरको साथमा रहनेछु।`;
    }

    res.json({ reply, source: 'backend_saathi_bridge' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.listen(PORT, () => {
  console.log(`Smrithi Saathi Backend API running on http://localhost:${PORT}`);
});
