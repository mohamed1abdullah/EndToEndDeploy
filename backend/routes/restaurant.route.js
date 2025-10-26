const express = require('express');
const router =  express.Router({ mergeParams: true });
const restaurantController = require('../controllers/Restaurant.controller');
const {body} = require('express-validator');
const auth = require('../middleware/auth');

// --- Reusable validation rules for CREATING a restaurant ---
// WHY: When creating a new document, we want to ensure all fields are present and valid.
const createRestaurantValidationRules = [
    body('Name').notEmpty().withMessage('Name is required'),
    body('Location').notEmpty().withMessage('Location is required'),
    body('Email').notEmpty().withMessage('Email is required').isEmail().withMessage('Email is not valid'),
    body('Password').notEmpty().withMessage('Password is required').isLength({min: 8}).withMessage('Password must be at least 8 characters long'),
    body('Phone').notEmpty().withMessage('Phone is required').isLength({min: 11}).withMessage('Enter a valid phone number'),
    body('Commercial_Num').notEmpty().withMessage('Commercial number is required')
];

// --- Reusable validation rules for UPDATING a restaurant ---
// WHY: For a PATCH request, we only want to validate the fields that are actually being sent.
// The .optional() method tells the validator to skip this rule if the field isn't in the request body.
const updateRestaurantValidationRules = [
    body('Name').optional().notEmpty().withMessage('Name cannot be empty'),
    body('Location').optional().notEmpty().withMessage('Location cannot be empty'),
    body('Email').optional().isEmail().withMessage('Email is not valid'),
    body('Password').optional().isLength({min: 8}).withMessage('Password must be at least 8 characters long'),
    body('Phone').optional().isLength({min: 11}).withMessage('Enter a valid phone number'),
    body('Commercial_Num').optional().notEmpty().withMessage('Commercial number cannot be empty')
];


// --- Routes ---

router.post('/login', restaurantController.login);

router.route('/')
    .get(restaurantController.getAllRestaurants)
    // Use the STRICT validation rules for the POST route
    .post(createRestaurantValidationRules, restaurantController.addRestaurant);

router.route('/:restaurantId')
    .get(restaurantController.getRestaurant)
    // Use the FLEXIBLE validation rules for the PATCH route
    .patch(auth, updateRestaurantValidationRules, restaurantController.updateRestaurant)
    .delete(auth, restaurantController.deleteRestaurant);

module.exports = router;
