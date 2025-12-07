// Simple WebSocket relay server for rooms/chatless signaling
// Run: `node signaling-server.js` (requires `ws` package)

const WebSocket = require('ws')
const port = process.env.PORT || 8080
const wss = new WebSocket.Server({ port })

// rooms: roomCode -> { players: [ws], ids: Map(ws->id) }
const rooms = new Map()

function makeId() { return Math.random().toString(36).substring(2, 8).toUpperCase() }

wss.on('connection', function connection(ws) {
    ws.id = makeId()
    ws.on('message', function incoming(message) {
        try {
            const msg = JSON.parse(message)
            handleMsg(ws, msg)
        } catch (e) { ws.send(JSON.stringify({ type: 'error', message: 'invalid json' })) }
    })
    ws.on('close', () => {
        // remove from rooms
        for (const [roomCode, info] of rooms.entries()) {
            if (info.players.includes(ws)) {
                info.players = info.players.filter(x => x !== ws)
                for (const p of info.players) p.send(JSON.stringify({ type: 'peer-left', playerId: ws.id }))
                if (info.players.length === 0) rooms.delete(roomCode)
            }
        }
    })
})

function handleMsg(ws, msg) {
    if (msg.type === 'create') {
        const room = makeId()
        rooms.set(room, { players: [ws] })
        ws.room = room
        ws.send(JSON.stringify({ type: 'created', room, playerId: ws.id }))
    } else if (msg.type === 'join') {
        const room = msg.room
        if (!rooms.has(room)) { ws.send(JSON.stringify({ type: 'error', message: 'room not found' })); return }
        const info = rooms.get(room)
        if (info.players.length >= 2) { ws.send(JSON.stringify({ type: 'error', message: 'room full' })); return }
        const other = info.players[0]
        info.players.push(ws)
        ws.room = room
        // notify both
        ws.send(JSON.stringify({ type: 'joined', room, playerId: ws.id, opponent: other.id }))
        other.send(JSON.stringify({ type: 'peer-joined', playerId: ws.id }))
    } else if (msg.type === 'move') {
        const room = msg.room
        if (!room || !rooms.has(room)) { ws.send(JSON.stringify({ type: 'error', message: 'room not found' })); return }
        const info = rooms.get(room)
        // broadcast move to other players
        for (const p of info.players) {
            if (p !== ws) p.send(JSON.stringify({ type: 'move', player: ws.id, move: msg.move }))
        }
    } else {
        ws.send(JSON.stringify({ type: 'error', message: 'unknown message type' }))
    }
}

console.log('Signaling server running on ws://0.0.0.0:' + port)
