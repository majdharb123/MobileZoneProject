const express = require("express");
const cors = require("cors");
require("dotenv").config();
const path = require("path");

const app = express();

app.use(cors());
app.use(express.json());

// API routes
const authRoutes = require("./Auth");
app.use("/api", authRoutes);
const categoryRoutes = require("./category");
app.use("/api", categoryRoutes);

const productRoutes = require("./product");
app.use("/api", productRoutes);

// uploads
app.use("/uploads", express.static(path.join(__dirname, "uploads")));

// Flutter Web
const flutterBuildPath = path.join(__dirname, "../test/build/web");
app.use(express.static(flutterBuildPath));

// ✅ الحل النهائي
app.use((req, res) => {
  res.sendFile(
    path.join(flutterBuildPath, "index.html")
  );
});

const PORT = process.env.PORT || 10000;
app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
});