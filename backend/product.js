const express = require("express");
const db = require("./db");
const multer = require("multer");
const path = require("path");
const fs = require("fs");

const product = express.Router();
product.use("/uploads", express.static("uploads"));

const storage = multer.diskStorage({
  destination: "./uploads",
  filename: function (req, file, cb) {
    cb(null, Date.now() + path.extname(file.originalname));
  },
});

const upload = multer({ storage: storage });

//Add Product
product.post("/addProduct", upload.single("image"), (req, res) => {
  const { name, category_id, description, price, stock } = req.body;
  const image = req.file ? req.file.filename : null;
  if (
    !name ||
    !category_id ||
    !description ||
    !price ||
    stock === undefined ||
    !image
  ) {
    return res.status(400).json({ message: "All fields are required" });
  }
  const sql = `INSERT INTO products (name,category_id,description,price,stock,image) VALUES (?,?,?,?,?,?)`;
  db.query(
    sql,
    [name, category_id, description, price, stock, image],
    (err, result) => {
      if (err) {
        console.log(err);
        return res.status(500).json({ message: "Error Adding Product" });
      }
      res.json({ message: "Added successful" });
    }
  );
});

product.get("/product", (req, res) => {
  const sql = `
    SELECT 
      products.id,
      products.name,
      products.description,
      products.price,
      products.stock,
      products.image,
      categories.name AS category_name
    FROM products
    JOIN categories ON products.category_id = categories.id
  `;

  db.query(sql, (err, result) => {
    if (err) {
      console.log(err);
      return res.status(500).json({ message: "Error fetching products" });
    }
    res.json(result);
  });
});

//Delete Product
product.delete("/product/:id", (req, res) => {
  const productId = req.params.id;
  const sql = "SELECT image FROM products WHERE id = ?";
  db.query(sql, [productId], (err, data) => {
    if (err) {
      console.log(err);
      return res.status(500).json({ message: "Error finding products" });
    }
    if (data.length === 0) {
      return res.status(404).json({ message: "Product not found" });
    }
    const imageFileName = data[0].image;
    if (imageFileName) {
      const imagePath = path.join(__dirname, "uploads", imageFileName);
      fs.unlink(imagePath, (err) => {
        console.error("Failed to delete local image:", err);
      });
    } else {
      console.log("Image deleted from folder");
    }

    const deleteSql = "DELETE FROM products WHERE id = ?";
    db.query(deleteSql, [productId], (err, result) => {
      if (err) {
        console.log(err);
        return res
          .status(500)
          .json({ message: "Error Deleting product from DB" });
      }
      res.json({ message: "Deleted successfully" });
    });
  });
});

module.exports = product;
