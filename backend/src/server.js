// Load environment variables first
require("dotenv").config();

const express = require("express");
const cors = require("cors");
const helmet = require("helmet");

const { initializeFirebase } = require("./config/firebase");
const { testDatabaseConnection } = require("./config/database");
const authRoutes = require("./routes/authRoutes");
const dashboardRoutes = require("./routes/dashboardRoutes");
const customerRoutes = require("./routes/customerRoutes");
const incomeRoutes = require("./routes/incomeRoutes");
const expenseRoutes = require("./routes/expenseRoutes");
const invoiceRoutes = require("./routes/invoiceRoutes");
const { authenticateUser } = require("./middleware/authMiddleware");

const app = express();

// Basic security middleware
app.use(helmet());

const defaultAllowedOrigins = [
    "http://localhost:5000",
    "http://127.0.0.1:5000",
    "http://localhost:5001",
    "http://127.0.0.1:5001",
    "http://10.0.2.2:5000"
];

const configuredOrigins = (process.env.CORS_ORIGIN || "")
    .split(",")
    .map((origin) => origin.trim())
    .filter(Boolean);

const allowedOrigins = [...new Set([...defaultAllowedOrigins, ...configuredOrigins])];
const isProd = process.env.NODE_ENV === "production";
const devOrigin = /^http:\/\/(localhost|127\.0\.0\.1):\d+$/;

const corsOptions = {
    origin: (origin, callback) => {
        if (!origin || allowedOrigins.includes(origin) || (!isProd && devOrigin.test(origin))) {
            callback(null, true);
            return;
        }

        callback(new Error("Origin not allowed by CORS."));
    },
    credentials: true,
    methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization"],
    optionsSuccessStatus: 204
};

// CORS configuration
app.use(cors(corsOptions));

// Parse incoming JSON requests
app.use(express.json());

// Authentication API routes
app.use("/api/auth", authRoutes);
app.use("/api/dashboard", dashboardRoutes);
app.use("/api/customers", customerRoutes);
app.use("/api/income", incomeRoutes);
app.use("/api/expenses", expenseRoutes);
app.use("/api/invoices", invoiceRoutes);

// Basic health-check route
app.get("/api/health", (req, res) => {
    res.status(200).json({
        success: true,
        message: "Smart Business Accounting API is running."
    });
});

// Protected test route
app.get("/api/auth/test", authenticateUser, (req, res) => {
    res.status(200).json({
        success: true,
        message: "Authentication successful.",
        user: {
            firebase_uid: req.user.uid,
            email: req.user.email
        }
    });
});

// Start backend server
async function startServer() {
    try {
        // Initialize Firebase
        initializeFirebase();

        // Test PostgreSQL connection
        const databaseConnected = await testDatabaseConnection();

        if (!databaseConnected) {
            throw new Error("Cannot start server without database connection.");
        }

        const PORT = process.env.PORT || 5000;

        app.listen(PORT, () => {
            console.log(`Backend server running on port ${PORT}.`);
        });

    } catch (error) {
        console.error("Backend startup failed:", error.message);
        return;
    }
}

startServer();