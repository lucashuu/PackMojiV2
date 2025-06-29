// Load environment variables from .env file
require('dotenv').config();

const express = require('express');
const cors = require('cors');
const rateLimit = require('express-rate-limit');

const app = express();
const PORT = process.env.PORT || 3000;

// Middlewares
app.use(cors()); // Enable Cross-Origin Resource Sharing
app.use(express.json()); // Parse JSON bodies

// Rate Limiter
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100, // limit each IP to 100 requests per windowMs
    standardHeaders: true, // Return rate limit info in the `RateLimit-*` headers
    legacyHeaders: false, // Disable the `X-RateLimit-*` headers
});
app.use(limiter);


// Basic Route for testing
app.get('/', (req, res) => {
    res.send('PackMoji API is running!');
});

// Import and use checklist routes
const checklistRoutes = require('./routes/checklist.routes');
app.use('/api/v1', checklistRoutes);


app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
}); 