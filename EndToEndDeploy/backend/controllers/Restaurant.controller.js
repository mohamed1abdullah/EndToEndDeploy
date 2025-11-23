let Restaurant = require('../models/Restaurant.model');
const {validationResult} = require('express-validator');
const jwt = require('jsonwebtoken');

// --- GET ALL RESTAURANTS ---
const getAllRestaurants = async (req, res) => {
    // WHY: Log when the function is initiated to trace the start of an action.
    console.log('[LOG] Attempting to fetch all restaurants...');
    try {
        const restaurants = await Restaurant.find();
        // WHY: Log success and include key data, like the number of items found.
        console.log(`[LOG] Success: Found ${restaurants.length} restaurants.`);
        res.json(restaurants);
    } catch (err) {
        // WHY: Log the full error to understand what went wrong on the server.
        console.error('[ERROR] Failed to fetch all restaurants:', err.message);
        res.status(500).send('Server Error');
    }
}

// --- GET A SINGLE RESTAURANT ---
const getRestaurant = async (req, res)=>{
    const restaurantId = req.params.restaurantId;
    // WHY: Log the incoming parameters to ensure the correct data is being processed.
    console.log(`[LOG] Attempting to fetch restaurant with ID: ${restaurantId}`);
    try{
        const restaurant = await Restaurant.findById(restaurantId);
        if(!restaurant){
            // WHY: Log specific business logic failures, like not finding a document.
            console.warn(`[WARN] No restaurant found with ID: ${restaurantId}`);
            return res.status(404).json({msg: "Restaurant not found"});
        }
       // WHY: Confirm that the requested document was found successfully.
       console.log(`[LOG] Success: Found restaurant "${restaurant.Name}" with ID: ${restaurantId}`);
       return res.json(restaurant);
    } catch(err){
        console.error(`[ERROR] Error fetching restaurant with ID ${restaurantId}:`, err.message);
        if (err.kind === 'ObjectId') {
            return res.status(404).json({ msg: 'Restaurant not found (Invalid ID format)' });
        }
        return res.status(500).send('Server Error');
    }
}

// --- ADD A NEW RESTAURANT ---
const addRestaurant = async (req, res)=>{
    console.log('[LOG] Attempting to add a new restaurant...');
    const errors = validationResult(req);
    if(!errors.isEmpty()){
        // WHY: Log validation failures to see exactly what data was invalid.
        console.warn('[WARN] Validation failed for new restaurant:', errors.array());
        return res.status(400).json({errors: errors.array()});
    }

    // WHY: Log the incoming request body (but NOT sensitive data like passwords in a real app).
    // For this educational purpose, we'll log it to see what's being sent from the frontend.
    console.log('[LOG] New restaurant data received:', req.body);

    try {
        const newRestaurant = new Restaurant(req.body);
        await newRestaurant.save();

        console.log(`[LOG] Success: Created new restaurant "${newRestaurant.Name}" with ID: ${newRestaurant._id}`);

        const payload = { user: { id: newRestaurant.id } };
        jwt.sign(payload, 'your-jwt-secret', { expiresIn: 3600 }, (err, token) => {
            if (err) throw err;
            console.log(`[LOG] Generated JWT for new restaurant ID: ${newRestaurant._id}`);
            res.status(201).json({ token, restaurant: newRestaurant });
          }
        );
    } catch (err) {
        console.error('[ERROR] Failed to add new restaurant:', err.message);
        res.status(500).send('Server Error');
    }
}

// --- UPDATE A RESTAURANT ---
const updateRestaurant = async (req, res)=>{
    const restaurantId = req.params.restaurantId;
    console.log(`[LOG] Attempting to update restaurant with ID: ${restaurantId}`);

    const errors = validationResult(req);
    if(!errors.isEmpty()){
        console.warn(`[WARN] Validation failed for updating restaurant ${restaurantId}:`, errors.array());
        return res.status(400).json({errors: errors.array()});
    }

    console.log(`[LOG] Update data for restaurant ${restaurantId}:`, req.body);
   try{
        const updatedRestaurant = await Restaurant.findByIdAndUpdate(
            restaurantId,
            { $set: req.body },
            { new: true } // This option returns the updated document
        );

        if (!updatedRestaurant) {
            console.warn(`[WARN] Update failed. No restaurant found with ID: ${restaurantId}`);
            return res.status(404).json({ msg: 'Restaurant not found' });
        }

        console.log(`[LOG] Success: Updated restaurant with ID: ${restaurantId}`);
        return res.status(200).json(updatedRestaurant);
    }catch(err){
        console.error(`[ERROR] Failed to update restaurant ${restaurantId}:`, err.message);
        return res.status(500).send('Server Error');
    }
}

// --- DELETE A RESTAURANT ---
const deleteRestaurant = async (req, res)=>{
    const restaurantId = req.params.restaurantId;
    console.log(`[LOG] Attempting to delete restaurant with ID: ${restaurantId}`);
    try{
        const result = await Restaurant.deleteOne({_id: restaurantId});
        if (result.deletedCount === 0) {
            console.warn(`[WARN] Delete failed. No restaurant found with ID: ${restaurantId}`);
            return res.status(404).json({ msg: 'Restaurant not found' });
        }
        console.log(`[LOG] Success: Deleted restaurant with ID: ${restaurantId}`);
        res.status(200).json({success: true, msg: "Restaurant deleted successfully"});
    }catch(err){
        console.error(`[ERROR] Failed to delete restaurant ${restaurantId}:`, err.message);
        return res.status(500).send('Server Error');
    }
}

// --- LOGIN ---
const login = async (req, res) => {
  const { email, password } = req.body;
  console.log(`[LOG] Login attempt for email: ${email}`);

  try {
    const restaurant = await Restaurant.findOne({ Email: email });
    if (!restaurant) {
      // WHY: Security: Don't reveal if the email or password was wrong. Log it for yourself, but send a generic message to the user.
      console.warn(`[WARN] Login failed: No user found for email: ${email}`);
      return res.status(400).json({ message: 'Invalid email or password' });
    }

    const isMatch = await restaurant.comparePassword(password);
    if (!isMatch) {
      console.warn(`[WARN] Login failed: Invalid password for email: ${email}`);
      return res.status(400).json({ message: 'Invalid email or password' });
    }
    
    console.log(`[LOG] Login successful for: ${email}`);
    const payload = { user: { id: restaurant.id } };

    jwt.sign(
      payload,
      'your-jwt-secret',
      { expiresIn: 3600 },
      (err, token) => {
        if (err) throw err;
        console.log(`[LOG] JWT generated for user ID: ${restaurant.id}`);
        res.status(200).json({
          message: 'Login successful',
          token: token,
          restaurantId: restaurant._id,
          name: restaurant.Name
        });
      }
    );
  } catch (err) {
    console.error('[ERROR] Server error during login:', err);
    res.status(500).json({ message: 'Server error' });
  }
};

module.exports = {
    getAllRestaurants,
    getRestaurant,
    addRestaurant,
    updateRestaurant,
    deleteRestaurant,
    login
}

