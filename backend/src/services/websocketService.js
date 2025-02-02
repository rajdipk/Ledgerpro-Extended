const WebSocket = require('ws');

class WebSocketService {
    constructor() {
        this.clients = new Set();
        this.adminClients = new Set();
    }

    initialize(server) {
        this.wss = new WebSocket.Server({ server });
        
        this.wss.on('connection', (ws, req) => {
            console.log('New WebSocket client connected');
            
            // Check if it's an admin connection
            const isAdmin = req.headers['x-admin-token'] === process.env.ADMIN_TOKEN;
            
            if (isAdmin) {
                this.adminClients.add(ws);
                this.sendAdminUpdate(ws);
            } else {
                this.clients.add(ws);
                this.sendPriceUpdate(ws);
            }

            ws.on('error', (error) => {
                console.error('WebSocket error:', error);
            });

            ws.on('close', () => {
                console.log('Client disconnected');
                this.clients.delete(ws);
                this.adminClients.delete(ws);
            });
        });
    }

    broadcastMessage(message) {
        this.clients.forEach(client => {
            if (client.readyState === WebSocket.OPEN) {
                client.send(JSON.stringify(message));
            }
        });
    }

    broadcastToAdmin(message) {
        this.adminClients.forEach(client => {
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

    sendAdminUpdate(client = null) {
        const update = {
            type: 'ADMIN_UPDATE',
            data: {
                prices: global.prices,
                timestamp: new Date().toISOString()
            }
        };

        if (client) {
            client.send(JSON.stringify(update));
        } else {
            this.broadcastToAdmin(update);
        }
    }
}

module.exports = new WebSocketService();
