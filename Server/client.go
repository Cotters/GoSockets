package main

const testClientHTML = `<!DOCTYPE html>
<html>
<head>
    <title>Game Server Test Client</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f0f0f0;
        }
        .container {
            display: flex;
            gap: 20px;
        }
        .panel {
            background: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .controls {
            flex: 1;
        }
        .canvas-container {
            flex: 2;
        }
        canvas {
            border: 2px solid #333;
            cursor: pointer;
            display: block;
        }
        .status {
            margin: 10px 0;
            padding: 10px;
            border-radius: 4px;
        }
        .connected {
            background-color: #d4edda;
            color: #155724;
        }
        .disconnected {
            background-color: #f8d7da;
            color: #721c24;
        }
        button {
            padding: 10px 20px;
            font-size: 16px;
            cursor: pointer;
            background-color: #007bff;
            color: white;
            border: none;
            border-radius: 4px;
            margin: 5px;
        }
        button:hover {
            background-color: #0056b3;
        }
        button:disabled {
            background-color: #ccc;
            cursor: not-allowed;
        }
        .player-list {
            margin-top: 20px;
        }
        .player-item {
            padding: 8px;
            margin: 5px 0;
            background-color: #f8f9fa;
            border-radius: 4px;
        }
        .player-item.me {
            background-color: #cce5ff;
            font-weight: bold;
        }
        .info {
            color: #666;
            font-size: 14px;
            margin: 10px 0;
        }
        h1 { color: #333; margin-top: 0; }
        h3 { color: #555; }
    </style>
</head>
<body>
    <h1>Game Server Test Client</h1>
    <div class="container">
        <div class="panel controls">
            <h3>Controls</h3>
            <div id="status" class="status disconnected">Disconnected</div>
            <button id="connectBtn" onclick="connect()">Connect</button>
            <button id="disconnectBtn" onclick="disconnect()" disabled>Disconnect</button>

            <div class="info">
                <p><strong>Instructions:</strong></p>
                <ul>
                    <li>Click "Connect" to join the game</li>
                    <li>Click on the canvas to move your player</li>
                    <li>Your player is shown in blue</li>
                    <li>Other players are shown in red</li>
                    <li>Max 10 players per room</li>
                </ul>
            </div>

            <div class="player-list">
                <h3>Players (<span id="playerCount">0</span>/10)</h3>
                <div id="players"></div>
            </div>
        </div>

        <div class="panel canvas-container">
            <h3>Game Map (800x600)</h3>
            <canvas id="gameCanvas" width="800" height="600"></canvas>
        </div>
    </div>

    <script>
        let ws = null;
        let myPlayerId = null;
        let players = new Map();
        const canvas = document.getElementById('gameCanvas');
        const ctx = canvas.getContext('2d');

        function connect() {
            const wsUrl = 'ws://' + window.location.host + '/ws';
            ws = new WebSocket(wsUrl);

            ws.onopen = function() {
                updateStatus(true);
                console.log('Connected to server');
            };

            ws.onclose = function() {
                updateStatus(false);
                console.log('Disconnected from server');
                players.clear();
                myPlayerId = null;
                drawCanvas();
            };

            ws.onerror = function(error) {
                console.error('WebSocket error:', error);
            };

            ws.onmessage = function(event) {
                const msg = JSON.parse(event.data);
                handleMessage(msg);
            };
        }

        function disconnect() {
            if (ws) {
                ws.close();
                ws = null;
            }
        }

        function handleMessage(msg) {
            console.log('Received:', msg);

            switch(msg.type) {
                case 'welcome':
                    myPlayerId = msg.playerId;
                    players.set(myPlayerId, {
                        id: myPlayerId,
                        x: msg.position.x,
                        y: msg.position.y
                    });
                    break;

                case 'playerJoined':
                    players.set(msg.playerId, {
                        id: msg.playerId,
                        x: msg.position.x,
                        y: msg.position.y
                    });
                    break;

                case 'playerLeft':
                    players.delete(msg.playerId);
                    break;

                case 'positionUpdate':
                    if (players.has(msg.playerId)) {
                        players.get(msg.playerId).x = msg.position.x;
                        players.get(msg.playerId).y = msg.position.y;
                    }
                    break;
            }

            updatePlayerList();
            drawCanvas();
        }

        function updateStatus(connected) {
            const status = document.getElementById('status');
            const connectBtn = document.getElementById('connectBtn');
            const disconnectBtn = document.getElementById('disconnectBtn');

            if (connected) {
                status.textContent = 'Connected';
                status.className = 'status connected';
                connectBtn.disabled = true;
                disconnectBtn.disabled = false;
            } else {
                status.textContent = 'Disconnected';
                status.className = 'status disconnected';
                connectBtn.disabled = false;
                disconnectBtn.disabled = true;
            }
        }

        function updatePlayerList() {
            const playerList = document.getElementById('players');
            const playerCount = document.getElementById('playerCount');
            playerCount.textContent = players.size;

            playerList.innerHTML = '';
            players.forEach((player, id) => {
                const div = document.createElement('div');
                div.className = 'player-item' + (id === myPlayerId ? ' me' : '');
                div.textContent = id === myPlayerId
                    ? 'You (' + id + ') - (' + player.x.toFixed(0) + ', ' + player.y.toFixed(0) + ')'
                    : 'Player ' + id + ' - (' + player.x.toFixed(0) + ', ' + player.y.toFixed(0) + ')';
                playerList.appendChild(div);
            });
        }

        function drawCanvas() {
            // Clear canvas
            ctx.fillStyle = '#ffffff';
            ctx.fillRect(0, 0, canvas.width, canvas.height);

            // Draw grid
            ctx.strokeStyle = '#e0e0e0';
            ctx.lineWidth = 1;
            for (let x = 0; x <= canvas.width; x += 50) {
                ctx.beginPath();
                ctx.moveTo(x, 0);
                ctx.lineTo(x, canvas.height);
                ctx.stroke();
            }
            for (let y = 0; y <= canvas.height; y += 50) {
                ctx.beginPath();
                ctx.moveTo(0, y);
                ctx.lineTo(canvas.width, y);
                ctx.stroke();
            }

            // Draw players
            players.forEach((player, id) => {
                const isMe = id === myPlayerId;
                ctx.fillStyle = isMe ? '#007bff' : '#dc3545';
                ctx.beginPath();
                ctx.arc(player.x, player.y, 10, 0, 2 * Math.PI);
                ctx.fill();

                // Draw player label
                ctx.fillStyle = '#000';
                ctx.font = '12px Arial';
                ctx.fillText(isMe ? 'You' : id.substring(0, 5), player.x + 15, player.y + 5);
            });
        }

        canvas.addEventListener('click', function(event) {
            if (!ws || ws.readyState !== WebSocket.OPEN) {
                alert('Please connect first!');
                return;
            }

            const rect = canvas.getBoundingClientRect();
            const x = event.clientX - rect.left;
            const y = event.clientY - rect.top;

            // Update local position immediately for smooth response
            if (players.has(myPlayerId)) {
                players.get(myPlayerId).x = x;
                players.get(myPlayerId).y = y;
                drawCanvas();
                updatePlayerList();
            }

            // Send position update to server
            const msg = {
                type: 'positionUpdate',
                position: { x: x, y: y }
            };
            ws.send(JSON.stringify(msg));
        });

        // Initial canvas draw
        drawCanvas();
    </script>
</body>
</html>`
