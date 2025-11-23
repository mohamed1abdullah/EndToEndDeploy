# Restaurant Management Portal

This is a simple front-end for a Restaurant Management Portal. It allows restaurant owners to create an account, manage their profile, and view a list of all registered restaurants.

## Features

*   **User Authentication:**
    *   Register a new restaurant account.
    *   Login with an existing account.
    *   Logout.
*   **Profile Management:**
    *   View and update restaurant profile information (name, email, location, phone, commercial number).
    *   Change password.
    *   Delete account.
*   **Restaurant Listing:**
    *   View a list of all registered restaurants.

## Getting Started

To run this project, you need to have a local server running that provides the necessary API endpoints.

1.  Clone this repository.
2.  Open `index.html` in your browser.
3.  Make sure the API server is running and accessible at `http://localhost:3001`.

## API Endpoints

This front-end application expects the following API endpoints:

*   `POST /restaurants/login`: Authenticate a user and get a token.
*   `POST /restaurants`: Register a new restaurant.
*   `GET /restaurants`: Get a list of all restaurants.
*   `GET /restaurants/:restaurantId`: Get the profile of a specific restaurant.
*   `PATCH /restaurants/:restaurantId`: Update the profile of a specific restaurant.
*   `DELETE /restaurants/:restaurantId`: Delete a specific restaurant.
