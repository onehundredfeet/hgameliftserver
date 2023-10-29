const WebSocket = require('ws');

const server = new WebSocket.Server({ port: 1337 });

server.on('connection', socket => {
    socket.on('message', message => {
        try {
            // Parse the incoming message as JSON
            const data = JSON.parse(message);

            // Process the data (this example simply echoes it back)
            const response = {
                status: "success",
                data: data
            };

            // Send a JSON response
            socket.send(JSON.stringify(response));

        } catch (e) {
            // Handle error if incoming message is not valid JSON
            const errorResponse = {
                status: "error",
                message: "Invalid JSON"
            };
            socket.send(JSON.stringify(errorResponse));
        }
    });

    socket.on('error', error => {
        console.error("WebSocket error:", error);
    });
});

console.log("WebSocket server started on ws://localhost:1337");