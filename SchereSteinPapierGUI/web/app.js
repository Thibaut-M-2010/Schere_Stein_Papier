// Minimal RPS game and websocket-based multiplayer
(function () {
    const $ = sel => document.querySelector(sel)
    const start = $('#start')
    const comp = $('#computer')
    const mp = $('#multiplayer')
    const btnComputer = $('#btn-computer')
    const btnMultiplayer = $('#btn-multiplayer')
    const btnBackComp = $('#btn-back-from-comp')
    const btnBackMp = $('#btn-back-from-mp')
    const btnCreate = $('#btn-create')
    const btnJoin = $('#btn-join')
    const joinCodeInput = $('#join-code')
    const mpStatus = $('#mp-status')
    const mpPlayArea = $('#mp-play-area')
    const opponentId = $('#opponent-id')
    const resultEl = $('#result')
    const compResultEl = $('#comp-result')

    let ws = null
    let room = null
    let playerId = null
    let opponent = null
    let lastMoves = {}

    function show(screen) { start.classList.add('hidden'); comp.classList.add('hidden'); mp.classList.add('hidden'); screen.classList.remove('hidden') }

    btnComputer.addEventListener('click', () => { show(comp) })
    btnMultiplayer.addEventListener('click', () => { show(mp) })
    btnBackComp.addEventListener('click', () => show(start))
    btnBackMp.addEventListener('click', () => { disconnectWS(); show(start) })

    // Computer play
    comp.querySelectorAll('.choice').forEach(b => b.addEventListener('click', () => {
        const move = b.dataset.move
        const ai = randomMove()
        const res = computeResult(move, ai)
        compResultEl.textContent = `You: ${move} — Computer: ${ai} => ${res}`
    }))

    // Multiplayer UI
    btnCreate.addEventListener('click', () => {
        connectWS()
        mpStatus.textContent = 'Creating room...'
        sendWS({ type: 'create' })
    })
    btnJoin.addEventListener('click', () => {
        const code = (joinCodeInput.value || '').trim().toUpperCase()
        if (!code) { mpStatus.textContent = 'Enter a join code.'; return }
        connectWS()
        mpStatus.textContent = `Joining ${code}...`
        sendWS({ type: 'join', room: code })
    })

    function getWsUrl() {
        // Local development: connect directly to localhost:8080
        if (location.hostname === 'localhost' || location.hostname === '127.0.0.1') {
            return 'ws://localhost:8080'
        }
        // Production: use secure websocket on same origin and proxy via /ws
        const proto = (location.protocol === 'https:') ? 'wss' : 'ws'
        return proto + '://' + location.host + '/ws'
    }

    function connectWS() {
        if (ws && ws.readyState === WebSocket.OPEN) return
        const url = getWsUrl()
        ws = new WebSocket(url)
        ws.addEventListener('open', () => { mpStatus.textContent = 'Connected to server.' })
        ws.addEventListener('message', e => {
            try { const m = JSON.parse(e.data); handleMessage(m) } catch (err) { console.warn('bad msg', e.data) }
        })
        ws.addEventListener('close', () => { mpStatus.textContent = 'Disconnected from server.'; mpPlayArea.classList.add('hidden') })
    }

    function disconnectWS() { if (ws) { try { ws.close() } catch (e) { } ws = null; room = null; playerId = null; opponent = null; lastMoves = {}; mpStatus.textContent = '' } }

    function sendWS(obj) { if (!ws) { mpStatus.textContent = 'Not connected to server'; return } ws.send(JSON.stringify(obj)) }

    function handleMessage(m) {
        if (m.type === 'created') {
            room = m.room; playerId = m.playerId; mpStatus.textContent = `Room created: ${room}. Share this code.`; joinCodeInput.value = room; mpPlayArea.classList.remove('hidden'); opponentId.textContent = 'Waiting...'
        } else if (m.type === 'joined') {
            room = m.room; playerId = m.playerId; opponent = m.opponent; mpStatus.textContent = `Joined room ${room}.`; mpPlayArea.classList.remove('hidden'); opponentId.textContent = m.opponent || '—'
        } else if (m.type === 'peer-joined') {
            opponent = m.playerId; mpStatus.textContent = `Player joined: ${opponent}`; opponentId.textContent = opponent
        } else if (m.type === 'move') {
            lastMoves[m.player] = m.move
            checkRound()
        } else if (m.type === 'error') {
            mpStatus.textContent = 'Error: ' + (m.message || '')
        }
    }

    // mp choice handlers
    mp.querySelectorAll('.choice').forEach(b => b.addEventListener('click', () => {
        const mv = b.dataset.move
        resultEl.textContent = 'Waiting for opponent...'
        sendWS({ type: 'move', room: room, move: mv })
        lastMoves[playerId || 'me'] = mv
        checkRound()
    }))

    function checkRound() {
        const players = Object.keys(lastMoves)
        if (!room) return
        if (players.length >= 2) {
            // determine players
            const [p1, p2] = players
            const a = lastMoves[p1], b = lastMoves[p2]
            const res = computeResult(a, b)
            let text
            if (res === 'draw') text = `Both chose ${a} — Draw.`
            else if (res === 'win') text = `${p1} wins: ${a} beats ${b}`
            else text = `${p2} wins: ${b} beats ${a}`
            resultEl.textContent = text
            // reset for next
            lastMoves = {}
        }
    }

    function randomMove() { return ['rock', 'paper', 'scissors'][Math.floor(Math.random() * 3)] }
    function computeResult(a, b) { if (!a || !b) return 'waiting'; if (a === b) return 'draw'; if ((a === 'rock' && b === 'scissors') || (a === 'scissors' && b === 'paper') || (a === 'paper' && b === 'rock')) return 'win'; return 'lose' }

    // expose small helper for manual testing
    window.__rps = { connectWS, disconnectWS }

})();
