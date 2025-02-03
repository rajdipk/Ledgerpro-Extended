const WebSocket = require('ws');

class WebSocketService {
    constructor() {
        this.clients = new Set();
        this.adminClients = new Set();
    }

    initialize(server) {
        this.wss = new WebSocket.Server({ 
            server,
            verifyClient: (info) => {
                const token = info.req.headers['x-admin-token'];
                console.log('WebSocket connection attempt:', {
                    token: token,
                    expected: process.env.ADMIN_TOKEN,
                    origin: info.req.headers.origin
                });
                return token === process.env.ADMIN_TOKEN;
            }
        });
        
        this.wss.on('connection', this.handleConnection.bind(this));
    }

    handleConnection(ws, req) {
        console.log('New WebSocket connection:', {
            origin: req.headers.origin,
            token: req.headers['x-admin-token']
        });

        const isAdmin = req.headers['x-admin-token'] === process.env.ADMIN_TOKEN;
        
        if (isAdmin) {
            this.adminClients.add(ws);
            this.sendAdminUpdate(ws);
        } else {
            this.clients.add(ws);
            this.sendPriceUpdate(ws);
        }

        ws.on('error', this.handleError.bind(this));
        ws.on('close', () => this.handleClose(ws));
    }

    handleError(error) {
        console.error('WebSocket error:', error);
    }

    handleClose(ws) {
        console.log('Client disconnected');
        this.clients.delete(ws);
        this.adminClients.delete(ws);
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
