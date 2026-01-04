const express = require("express");
const bcrypt = require("bcryptjs");
const db = require("./db");
const jwt = require("jsonwebtoken");

const auth = express.Router();

//register
auth.post("/register", async (req, res) => {
  const { name, email, password } = req.body;
  if (!name || !email || !password) {
    return res.status(400).json({ message: "All fields are required" });
  }

  const hashedPassword = await bcrypt.hash(password, 10);

  const sql = `INSERT INTO users (name,email,password,is_admin) VALUES (?,?,?,0)`;
  db.query(sql, [name, email, hashedPassword], (err) => {
    if (err) {
      console.log(err);
      return res.status(500).json({ message: "Error registering user" });
    }
    res.json({ message: "Registration successful" });
  });
});

//login
auth.post("/login", async (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) {
    return res.status(400).json({ message: "All fields are required" });
  }
  const sql = `SELECT * FROM users WHERE email = ?`;
  db.query(sql, [email], async (err, result) => {
    if (err) return res.status(500).json(err);
    if (result.length === 0)
      return res.status(400).json({ message: "User not found" });
    const user = result[0];
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) return res.status(400).json({ message: "Wrong password" });

    const token = jwt.sign(
      { id: user.id, email: user.email },
      process.env.JWT_SECRET || "fallback_secret_key",
      { expiresIn: "1h" }
    );

    res.json({
      message: "Login successful",
      token,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        isAdmin: user.is_admin,
      },
    });
  });
});


module.exports = auth;
