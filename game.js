// Snake game for Bicep 5 Year Anniversary
const canvas = document.getElementById('game-canvas');
const ctx = canvas.getContext('2d');
const startScreen = document.getElementById('start-screen');
const endScreen = document.getElementById('end-screen');
const startBtn = document.getElementById('start-btn');
const restartBtn = document.getElementById('restart-btn');
const playerNameInput = document.getElementById('player-name');
const finalScore = document.getElementById('final-score');
const highScoresList = document.getElementById('high-scores');

const gridSize = 20;
const tileCountX = canvas.width / gridSize;
const tileCountY = canvas.height / gridSize;
let snake, direction, nextDirection, bicep, score, gameInterval, gameOver;
let monsterTimer = 0;

const didYouKnowFacts = [
    "Did you know? Bicep 0.1 was released in 2020 as an experimental project to simplify ARM templates!",
    "Did you know? Bicep 0.2 introduced modules, making code reuse and organization much easier.",
    "Did you know? Bicep 0.3 brought type safety and improved tooling for a better developer experience.",
    "Did you know? Bicep 0.4 added support for symbolic names and improved resource referencing.",
    "Did you know? Bicep 0.5 enabled decompilation of ARM templates back to Bicep code!",
    "Did you know? Bicep 0.6 introduced extensibility and new language features.",
    "Did you know? Bicep 0.7 brought linter improvements and better error messages.",
    "Did you know? Bicep 0.8 added support for loops and conditions directly in the language.",
    "Did you know? Bicep 0.9 improved module registry and introduced new resource types.",
    "Did you know? Bicep 0.10 and beyond have continued to add features, performance, and Azure integration!",
    "Did you know? Bicep supports parameter files for easier configuration management?",
    "Did you know? Bicep has a VS Code extension for syntax highlighting and IntelliSense?",
    "Did you know? Bicep code is transpiled to standard ARM JSON templates?",
    "Did you know? Bicep supports resource loops for scalable deployments?",
    "Did you know? Bicep has built-in linting to help you write better code?",
    "Did you know? Bicep supports conditional resource deployment?",
    "Did you know? Bicep modules can be published and shared via registries?",
    "Did you know? Bicep supports symbolic names for easier resource referencing?",
    "Did you know? Bicep is open source and welcomes community contributions?",
    "Did you know? Bicep supports string interpolation for dynamic values?",
    "Did you know? Bicep has a playground for trying out code online?",
    "Did you know? Bicep supports output variables for sharing values between modules?",
    "Did you know? Bicep supports secure parameters for secrets?",
    "Did you know? Bicep can decompile existing ARM templates to Bicep code?",
    "Did you know? Bicep supports resource tags for better management?",
    "Did you know? Bicep supports resource property iteration?",
    "Did you know? Bicep supports importing modules from public and private registries?",
    "Did you know? Bicep supports type definitions for parameters and outputs?",
    "Did you know? Bicep supports resource dependencies with the dependsOn keyword?",
    "Did you know? Bicep supports resource copy loops for batch deployments?",
    "Did you know? Bicep supports comments for better documentation?",
    "Did you know? Bicep supports resourceId and subscriptionResourceId functions?",
    "Did you know? Bicep supports secureString and secureObject parameter types?",
    "Did you know? Bicep supports resource property expressions?",
    "Did you know? Bicep supports resource group and subscription-level deployments?",
    "Did you know? Bicep supports decorators for parameter validation?",
    "Did you know? Bicep supports default values for parameters?",
    "Did you know? Bicep supports importing existing resources with existing keyword?",
    "Did you know? Bicep supports for-expressions for arrays and objects?",
    "Did you know? Bicep supports resource symbolic names for easier reference?",
    "Did you know? Bicep supports outputting objects and arrays?",
    "Did you know? Bicep supports resource property conditions?",
    "Did you know? Bicep supports module outputs for sharing data?",
    "Did you know? Bicep supports resource property defaults?",
    "Did you know? Bicep supports resource property secure values?",
    "Did you know? Bicep supports resource property expressions in loops?",
    "Did you know? Bicep supports resource property conditions in loops?",
    "Did you know? Bicep supports resource property defaults in loops?",
    "Did you know? Bicep supports resource property secure values in loops?",
    "Did you know? Bicep supports resource property expressions in conditions?",
    "Did you know? Bicep supports resource property defaults in conditions?",
    "Did you know? Bicep supports resource property secure values in conditions?"
];
let factIndex = 0;
const didYouKnowBox = document.getElementById('did-you-know');

// Monster logic
const monsterImage = new Image();
monsterImage.src = 'data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32"><rect width="32" height="32" rx="6" fill="%23d32f2f"/><line x1="8" y1="8" x2="24" y2="24" stroke="white" stroke-width="4" stroke-linecap="round"/><line x1="24" y1="8" x2="8" y2="24" stroke="white" stroke-width="4" stroke-linecap="round"/></svg>';

let monsters = [];

function resetGame() {
    snake = [
        { x: 8, y: 10 },
        { x: 7, y: 10 },
        { x: 6, y: 10 }
    ];
    direction = 'right';
    nextDirection = 'right';
    score = 0;
    gameOver = false;
    placeBicep();
    monsters = [];
    monsterTimer = 0;
}

function placeBicep() {
    let valid = false;
    while (!valid) {
        bicep = {
            x: Math.floor(Math.random() * tileCountX),
            y: Math.floor(Math.random() * tileCountY)
        };
        valid = !snake.some(seg => seg.x === bicep.x && seg.y === bicep.y)
            && !monsters.some(m => m.x === bicep.x && m.y === bicep.y);
    }
}

function drawSnake() {
    const bicepImg = new Image();
    bicepImg.src = 'BicepLogoImage.png';
    snake.forEach((seg, i) => {
        if (bicepImg.complete) {
            // Draw the head in blue (first segment)
            ctx.drawImage(bicepImg, seg.x * gridSize, seg.y * gridSize, gridSize, gridSize);
        } else {
            bicepImg.onload = () => {
                ctx.drawImage(bicepImg, seg.x * gridSize, seg.y * gridSize, gridSize, gridSize);
            };
        }
    });
}

function drawBicep() {
    const bicepImg = new Image();
    bicepImg.src = 'BicepLogoImage.png';
    if (bicepImg.complete) {
        ctx.drawImage(bicepImg, bicep.x * gridSize, bicep.y * gridSize, gridSize, gridSize);
    } else {
        bicepImg.onload = () => {
            ctx.drawImage(bicepImg, bicep.x * gridSize, bicep.y * gridSize, gridSize, gridSize);
        };
    }
}

function drawScore() {
    ctx.fillStyle = '#222';
    ctx.font = '18px Arial';
    ctx.fillText(`Score: ${score}`, 10, 24);
}

function showDidYouKnow() {
    if (factIndex < didYouKnowFacts.length) {
        const fact = didYouKnowFacts[factIndex];
        if (fact.startsWith("Did you know?")) {
            didYouKnowBox.innerHTML = 'Did you know?<br>' + fact.slice(14).trim();
        } else {
            didYouKnowBox.textContent = fact;
        }
        didYouKnowBox.style.display = 'block';
        didYouKnowBox.classList.add('active');
        factIndex++;
    }
}

function resetDidYouKnow() {
    factIndex = 0;
    didYouKnowBox.textContent = '';
    didYouKnowBox.style.display = 'none';
    didYouKnowBox.classList.remove('active');
}

function spawnMonster() {
    let valid = false, mx, my;
    while (!valid) {
        mx = Math.floor(Math.random() * tileCountX);
        my = Math.floor(Math.random() * tileCountY);
        valid = !snake.some(seg => seg.x === mx && seg.y === my) && (bicep.x !== mx || bicep.y !== my);
    }
    monsters.push({ x: mx, y: my });
}

function drawMonsters() {
    monsters.forEach(m => {
        ctx.drawImage(monsterImage, m.x * gridSize, m.y * gridSize, gridSize, gridSize);
    });
}

function checkMonsterCollision(head) {
    return monsters.some(m => m.x === head.x && m.y === head.y);
}

function updateMonsters() {
    // Spawn a monster every 7 seconds, up to 3 on screen
    monsterTimer++;
    if (monsterTimer > 70 && monsters.length < 3) {
        spawnMonster();
        monsterTimer = 0;
    }
}

function updateSnake() {
    let head = { ...snake[0] };
    direction = nextDirection;
    if (direction === 'right') head.x++;
    if (direction === 'left') head.x--;
    if (direction === 'up') head.y--;
    if (direction === 'down') head.y++;

    // Wrap around screen (continue play if hit border)
    if (head.x < 0) head.x = tileCountX - 1;
    if (head.x >= tileCountX) head.x = 0;
    if (head.y < 0) head.y = tileCountY - 1;
    if (head.y >= tileCountY) head.y = 0;

    // Check monster collision
    if (checkMonsterCollision(head)) {
        gameOver = true;
        return;
    }
    // Check self collision
    if (snake.some(seg => seg.x === head.x && seg.y === head.y)) {
        gameOver = true;
        return;
    }
    snake.unshift(head);
    // Check bicep pickup
    if (head.x === bicep.x && head.y === bicep.y) {
        score++;
        placeBicep();
        showDidYouKnow();
    } else {
        snake.pop();
    }
}

function draw() {
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    drawSnake();
    drawBicep();
    drawMonsters();
    drawScore();
}

// Use localStorage for high scores (browser only)
function getHighScores() {
    return JSON.parse(localStorage.getItem('bicepHighScores') || '[]');
}

function saveHighScores(scores) {
    localStorage.setItem('bicepHighScores', JSON.stringify(scores));
}

function addHighScore(name, score) {
    let scores = getHighScores();
    scores.push({ name, score });
    scores = scores.sort((a, b) => b.score - a.score).slice(0, 10);
    saveHighScores(scores);
    return scores;
}

function renderHighScores(scores) {
    highScoresList.innerHTML = '';
    scores.forEach(entry => {
        if (entry && entry.name !== undefined && entry.score !== undefined) {
            const li = document.createElement('li');
            li.textContent = `${entry.name} - ${entry.score}`;
            highScoresList.appendChild(li);
        }
    });
}

function showEndScreen() {
    canvas.style.display = 'none';
    endScreen.style.display = 'block';
    finalScore.textContent = `You collected ${score} Bicep icons!`;
    const playerName = canvas.dataset.playerName || 'Player';
    const scores = addHighScore(playerName, score);
    renderHighScores(scores);
    didYouKnowBox.style.display = 'none'; // Hide did you know box when game ends
}

function gameLoop() {
    if (gameOver) {
        clearInterval(gameInterval);
        setTimeout(showEndScreen, 300);
        return;
    }
    updateMonsters();
    updateSnake();
    draw();
}

startBtn.onclick = () => {
    const playerName = playerNameInput.value.trim();
    if (!playerName) {
        playerNameInput.focus();
        playerNameInput.style.borderColor = 'red';
        playerNameInput.placeholder = 'Please enter your name!';
        return;
    } else {
        playerNameInput.style.borderColor = '#ccc';
        playerNameInput.placeholder = 'Enter your name';
    }
    startScreen.style.display = 'none';
    canvas.style.display = 'block';
    endScreen.style.display = 'none';
    resetGame();
    draw();
    resetDidYouKnow();
    gameInterval = setInterval(gameLoop, 100);
    canvas.dataset.playerName = playerName;
    // Show latest high scores at game start
    const scores = getHighScores();
    renderHighScores(scores);
};

restartBtn.onclick = () => {
    startBtn.onclick();
};

document.addEventListener('keydown', (e) => {
    if (e.key === 'ArrowUp' && direction !== 'down') nextDirection = 'up';
    if (e.key === 'ArrowDown' && direction !== 'up') nextDirection = 'down';
    if (e.key === 'ArrowLeft' && direction !== 'right') nextDirection = 'left';
    if (e.key === 'ArrowRight' && direction !== 'left') nextDirection = 'right';
});

window.onload = () => {
    playerNameInput.focus();
};

playerNameInput.addEventListener('keydown', (e) => {
    if (e.key === 'Enter') {
        startBtn.onclick();
    }
});
