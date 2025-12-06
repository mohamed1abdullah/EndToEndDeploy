const Restaurant = require('../models/Restaurant.model');
const { validationResult } = require('express-validator');
const jwt = require('jsonwebtoken');

// --- GET ALL ---
const getAllRestaurants = async (req, res) => {
  try {
    const restaurants = await Restaurant.find();
    res.json(restaurants);
  } catch (err) {
    console.error(err);
    res.status(500).send("Server Error");
  }
};

// --- GET ONE ---
const getRestaurant = async (req, res) => {
  try {
    const restaurant = await Restaurant.findById(req.params.restaurantId);

    if (!restaurant) return res.status(404).json({ msg: "Restaurant not found" });

    res.json(restaurant);
  } catch (err) {
    console.error(err);
    res.status(500).send("Server Error");
  }
};

// --- CREATE ---
const addRestaurant = async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });

  try {
    const restaurant = await Restaurant.create(req.body);

    const payload = { user: { id: restaurant.id } };
    const token = jwt.sign(payload, 'your-jwt-secret', { expiresIn: 3600 });

    res.status(201).json({ token, restaurant });
  } catch (err) {
    console.error(err);
    res.status(500).send("Server Error");
  }
};

// --- UPDATE ---
const updateRestaurant = async (req, res) => {
  try {
    const updated = await Restaurant.update(req.params.restaurantId, req.body);
    res.json(updated);
  } catch (err) {
    console.error(err);
    res.status(500).send("Server Error");
  }
};

// --- DELETE ---
const deleteRestaurant = async (req, res) => {
  try {
    await Restaurant.delete(req.params.restaurantId);
    res.json({ msg: "Restaurant deleted" });
  } catch (err) {
    console.error(err);
    res.status(500).send("Server Error");
  }
};

// --- LOGIN ---
const login = async (req, res) => {
  const { email, password } = req.body;

  try {
    const restaurant = await Restaurant.findOne({ Email: email });
    if (!restaurant) return res.status(400).json({ message: "Invalid email or password" });

    const isMatch = await restaurant.comparePassword(password);
    if (!isMatch) return res.status(400).json({ message: "Invalid email or password" });

    const payload = { user: { id: restaurant.id } };
    const token = jwt.sign(payload, 'your-jwt-secret', { expiresIn: 3600 });

    res.json({
      message: "Login successful",
      token,
      restaurantId: restaurant.id,
      name: restaurant.Name
    });
  } catch (err) {
    console.error(err);
    res.status(500).send("Server Error");
  }
};

module.exports = {
  getAllRestaurants,
  getRestaurant,
  addRestaurant,
  updateRestaurant,
  deleteRestaurant,
  login
};
