const express = require("express");
const db = require("./db");

const category = express.Router();

//Get Category;
category.get("/category", (req, res) => {
  const sql = `SELECT * FROM categories`;
  db.query(sql, (err, data) => {
    if (err) return res.json({ Error: "Error fetching brands" });
    return res.json(data);
  });
});

module.exports = category;
