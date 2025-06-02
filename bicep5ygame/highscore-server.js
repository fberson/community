// Simple Express backend for Bicep Snake high scores
const express = require('express');
const cors = require('cors');
const fs = require('fs');
const app = express();
const PORT = process.env.PORT || 3001;
const HIGHSCORES_FILE = 'highscores.json';

app.use(cors());
app.use(express.json());

function loadScores() {
    if (!fs.existsSync(HIGHSCORES_FILE)) return [];
    try {
        return JSON.parse(fs.readFileSync(HIGHSCORES_FILE, 'utf8'));
    } catch {
        return [];
    }
}

function saveScores(scores) {
    fs.writeFileSync(HIGHSCORES_FILE, JSON.stringify(scores, null, 2));
}

app.get('/highscores', (req, res) => {
    const scores = loadScores();
    console.log('GET /highscores ->', scores);
    res.json(scores.slice(0, 10));
});

// Restore the Express POST endpoint for browser-based high score saving
app.post('/highscores', (req, res) => {
    const { name, score, time } = req.body;
    console.log('POST /highscores <-', req.body);
    if (!name || typeof score !== 'number' || typeof time !== 'number') {
        console.log('POST /highscores error: Invalid payload', req.body);
        return res.status(400).json({ error: 'Invalid payload' });
    }
    let scores = loadScores();
    scores.push({ name, score, time });
    // Sort by score desc, then time asc
    scores = scores.sort((a, b) => b.score - a.score || a.time - b.time).slice(0, 10);
    saveScores(scores);
    console.log('POST /highscores ->', scores);
    res.json(scores);
});

app.listen(PORT, () => {
    console.log(`High score server running on port ${PORT}`);
});
