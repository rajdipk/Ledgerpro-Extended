const WebSocket = require('ws');

class WebSocketService {
    constructor() {
        this.clients = new Set();
    }

    initialize(server) {
        this.wss = new WebSocket.Server({ server });
        
        this.wss.on('connection', (ws) => {
            console.log('New WebSocket client connected');
            this.clients.add(ws);

            ws.on('error', (error) => {
                console.error('WebSocket error:', error);
            });

            ws.on('close', () => {
                console.log('Client disconnected');
                this.clients.delete(ws);
            });

            // Send current prices on connection
            this.sendPriceUpdate(ws);
        });
    }

    broadcastMessage(message) {
        this.clients.forEach(client => {
            if (client.readyState === WebSocket.OPEN) {
                client.send(JSON.stringify(message));
            }
        });
    }

    sendPriceUpdate(client = null) {
        const priceUpdate = {
            type: 'PRICE_UPDATE',
            data: {
                professional: global.prices?.professional || 599,
                enterprise: global.prices?.enterprise || 999
            },
            timestamp: new Date().toISOString()
        };

        if (client) {
            client.send(JSON.stringify(priceUpdate));
        } else {
            this.broadcastMessage(priceUpdate);
        }
    }
}

module.exports = new WebSocketService();
