const express = require('express');
const mongoose = require('mongoose');
const mongoSanitize = require('express-mongo-sanitize');
const morgan = require('morgan');
const cors = require('cors'); // <-- Will now be found

// Route imports
const restaurantRouter = require('./routes/restaurant.route');
// const frontendRouter = require('./routes/frontend.route'); // <-- REMOVED

// Initialize app
const app = express();

// --- Middleware Setup ---

// Enable CORS for all routes so your future frontend can make requests
app.use(cors());

// Use morgan for detailed request logging
app.use(morgan('dev'));

// Body parser to make `req.body` available
app.use(express.json());

// Sanitize data after parsing
app.use(mongoSanitize({
  // This option is needed for compatibility with newer Express versions
  // Although we downgraded, it's good practice to keep it.
  onSanitize: ({ req, key }) => {
    console.warn(`[Sanitize] This request[${key}] is sanitized`, req);
  },
}));


// --- REMOVED STATIC FILE SERVING ---
// app.use(express.static(path.join(__dirname, 'views')));
// app.use('/css', express.static(path.join(__dirname, 'views/css')));
// app.use('/js', express.static(path.join(__dirname, 'views/js')));

// --- Database Connection ---
const uri = process.env.MONGODB_URI || "mongodb://localhost:27017/res";
mongoose.connect(uri).then(() => {
    console.log("✅ [API] Successfully connected to MongoDB");
});

// --- API Routes ---
app.use("/restaurants", restaurantRouter);
// app.use('/', frontendRouter); // <-- REMOVED

// --- Start Server ---
// We'll run the backend on port 3001 to prepare for a separate frontend later.
const PORT = 3001;
app.listen(PORT, () => {
    console.log(`🚀 [API] Server is running on http://localhost:${PORT}/`);
});

