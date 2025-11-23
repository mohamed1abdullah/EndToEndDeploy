const express = require('express');
const router = express.Router();
const path = require('path');

router.get('/login', (req, res) => {
  res.sendFile(path.join(__dirname, '../views/html/login.html'));
});

router.get('/register', (req, res) => {
  res.sendFile(path.join(__dirname, '../views/html/register.html'));
});

module.exports = router;