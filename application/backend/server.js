const express = require('express');
const morgan = require('morgan');
const cors = require('cors');
require("dotenv").config();

// AWS DynamoDB
const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient } = require("@aws-sdk/lib-dynamodb");

// --- Initialize app ---
const app = express();

// --- Middleware ---
app.use(cors());
app.use(morgan('dev'));
app.use(express.json());

// --- DynamoDB Client ---
const ddbClient = new DynamoDBClient({
  region: process.env.AWS_REGION || "us-east-1",
});

global.db = DynamoDBDocumentClient.from(ddbClient);

// --- Routes ---
const restaurantRouter = require('./routes/restaurant.route');
app.use("/restaurants", restaurantRouter);

// --- Start Server ---
const PORT = 3001;
app.listen(PORT, () => {
  console.log(`🚀 Server running on http://localhost:${PORT}`);
});
