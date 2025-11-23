🍽️ Restaurant Management Backend

This backend powers a restaurant management platform that allows restaurants to manage their profiles, update details, and handle authentication securely.

Built with Node.js, Express, and MongoDB, it provides a RESTful API with JWT-based authentication and robust validation.

📁 Folder Structure

/
├── controllers/
│   └── Restaurant.controller.js
├── middleware/
│   └── auth.js
├── models/
│   └── Restaurant.model.js
├── routes/
│   └── restaurant.route.js
├── .env
├── package.json
└── server.js


🚀 Features

Restaurant Management: CRUD (Create, Read, Update, Delete) operations for restaurants.

Authentication: Secure user login with JSON Web Tokens (JWT).

Password Hashing: Passwords are securely hashed using bcrypt before being stored in the database.

Input Validation: Robust input validation for all API endpoints to ensure data integrity.

Request Logging: Detailed request logging for debugging and monitoring.

Data Sanitization: Protection against NoSQL injection attacks.

🛠️ Technologies Used

Node.js: JavaScript runtime environment.

Express.js: Web framework for Node.js.

MongoDB: NoSQL database for storing restaurant data.

Mongoose: ODM (Object Data Modeling) library for MongoDB.

jsonwebtoken: For generating and verifying JSON Web Tokens.

bcrypt: For hashing passwords.

express-validator: For request body validation.

cors: For enabling Cross-Origin Resource Sharing.

morgan: For HTTP request logging.

express-mongo-sanitize: For sanitizing user-supplied data to prevent NoSQL injection.

⚙️ Environment Variables

To run this project, you will need to add the following environment variables to your .env file:

MONGODB_URI=mongodb://localhost:27017/restaurant_db
JWT_SECRET=your_jwt_secret
PORT=3001


🧩 Installation and Setup

Clone the repository:

git clone <repository-url>


Install dependencies:

npm install


Set up your environment variables:
Create a .env file in the root directory and add the necessary variables as shown in the "Environment Variables" section.

Start the server:

For production:

npm start


For development (with automatic reloading):

npm run dev


The server will be running on http://localhost:3001.

🔗 API Endpoints

Authentication

POST /restaurants/login

Description: Authenticates a restaurant and returns a JWT token.

Request Body:

{
  "email": "restaurant@example.com",
  "password": "password123"
}


Response:

{
  "message": "Login successful",
  "token": "your-jwt-token",
  "restaurantId": "restaurant-id",
  "name": "Restaurant Name"
}


Restaurants

GET /restaurants

Description: Get all restaurants.

Response: An array of restaurant objects.

POST /restaurants

Description: Create a new restaurant.

Request Body:

{
  "Name": "New Restaurant",
  "Location": "123 Main St",
  "Email": "new@example.com",
  "Password": "password123",
  "Phone": "12345678901",
  "Commercial_Num": 12345
}


Response: The newly created restaurant object and a JWT token.

GET /restaurants/:restaurantId

Description: Get a single restaurant by its ID.

Response: A single restaurant object.

PATCH /restaurants/:restaurantId

Description: Update a restaurant's information. Requires a valid JWT token in the Authorization header.

Request Body: (Include only the fields you want to update)

{
  "Name": "Updated Restaurant Name",
  "Phone": "09876543210"
}


Response: The updated restaurant object.

DELETE /restaurants/:restaurantId

Description: Delete a restaurant. Requires a valid JWT token in the Authorization header.

Response:

{
  "success": true,
  "msg": "Restaurant deleted successfully"
}


🔒 Authentication

This API uses JSON Web Tokens (JWT) for authentication. To access protected routes, you need to include the token in the Authorization header of your requests with the "Bearer" scheme:

Authorization: Bearer <your-jwt-token>


🧱 Future Improvements

Add role-based access control (admin vs restaurant)

Implement refresh tokens

Add pagination to restaurant list

📄 License

This project is licensed private

💻 Developed by tariq
