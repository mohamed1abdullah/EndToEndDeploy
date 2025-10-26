const mongoose = require('mongoose');
const bcrypt = require('bcrypt');
const RestaurantSchema = new mongoose.Schema({
    Name:{
        type : String,
        required: true
    },
    Email:{
        type: String,
        required: true,
        unique: true
    },
    Password:{
        type: String,
        required: true
    },
    Commercial_Num:{
        type: Number,
        required: true,
        unique: true
    },
    Phone:{
        type: String,
        required: true,
        unique: true
    },
    Location:{
        type: String,
        required: true
    },
    img:{
        type: String
    }
});

RestaurantSchema.pre('save', async function (next) {
  if (!this.isModified('Password')) return next();
  this.Password = await bcrypt.hash(this.Password, 10);
  next();
});

RestaurantSchema.methods.comparePassword = async function (password) {
  return await bcrypt.compare(password, this.Password);
};
module.exports = mongoose.model("Restaurant", RestaurantSchema);