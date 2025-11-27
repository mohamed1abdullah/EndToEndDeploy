document.addEventListener('DOMContentLoaded', () => {

    // --- CONFIG ---
    const API_BASE_URL = 'http://18.205.3.133:3001'; // From your server.js

    // --- STATE ---
    let appState = {
        token: localStorage.getItem('token'),
        restaurantId: localStorage.getItem('restaurantId'),
        name: localStorage.getItem('name'),
        currentPage: null
    };

    // --- SELECTORS ---
    // Pages
    const loginPage = document.getElementById('login-page');
    const registerPage = document.getElementById('register-page');
    const managementPage = document.getElementById('management-page');
    const allRestaurantsPage = document.getElementById('all-restaurants-page');
    const pages = [loginPage, registerPage, managementPage, allRestaurantsPage];
    
    // Loader
    const loadingOverlay = document.getElementById('loading-overlay');
    
    // Nav
    const navLinks = document.getElementById('nav-links');
    
    // Forms
    const loginForm = document.getElementById('login-form');
    const registerForm = document.getElementById('register-form');
    const managementForm = document.getElementById('management-form');

    // ... (all other form input selectors remain the same) ...
    // Form Inputs: Register
    const regName = document.getElementById('reg-name');
    const regEmail = document.getElementById('reg-email');
    const regPassword = document.getElementById('reg-password');
    const regLocation = document.getElementById('reg-location');
    const regPhone = document.getElementById('reg-phone');
    const regCommercial = document.getElementById('reg-commercial');

    // Form Inputs: Login
    const loginEmail = document.getElementById('login-email');
    const loginPassword = document.getElementById('login-password');

    // Form Inputs: Management
    const mgmtName = document.getElementById('mgmt-name');
    const mgmtEmail = document.getElementById('mgmt-email');
    const mgmtLocation = document.getElementById('mgmt-location');
    const mgmtPhone = document.getElementById('mgmt-phone');
    const mgmtCommercial = document.getElementById('mgmt-commercial');
    const mgmtPassword = document.getElementById('mgmt-password');
    const welcomeMessage = document.getElementById('welcome-message');

    // Buttons & Links
    const showRegisterLink = document.getElementById('show-register-link');
    const showLoginLink = document.getElementById('show-login-link');
    const deleteAccountBtn = document.getElementById('delete-account-btn');
    
    // Content Areas
    const restaurantListContainer = document.getElementById('restaurant-list');
    const toastContainer = document.getElementById('toast-container');


    // --- FUNCTIONS ---

    /**
     * Shows the loading spinner
     */
    function showLoader() {
        if (loadingOverlay) loadingOverlay.style.display = 'flex';
    }

    /**
     * Hides the loading spinner
     */
    function hideLoader() {
        if (loadingOverlay) loadingOverlay.style.display = 'none';
    }

    /**
     * Hides all pages and shows the specified one with a fade animation
     * @param {HTMLElement} pageToShow The page element to display
     */
    function showPage(pageToShow) {
        if (appState.currentPage === pageToShow) return;

        // Hide the current page
        if (appState.currentPage) {
            appState.currentPage.classList.remove('page-active');
        }

        // Show the new page
        if (pageToShow) {
            pageToShow.classList.add('page-active');
            appState.currentPage = pageToShow;
        } else {
            appState.currentPage = null;
        }
    }

    /**
     * Updates the navigation bar based on auth state
     */
    function updateNavbar() {
        navLinks.innerHTML = ''; // Clear existing links
        
        // Always show "All Restaurants"
        const allRestaurantsLink = document.createElement('a');
        allRestaurantsLink.href = '#';
        allRestaurantsLink.textContent = 'All Restaurants';
        allRestaurantsLink.className = 'nav-link';
        allRestaurantsLink.id = 'nav-all-restaurants';
        navLinks.appendChild(allRestaurantsLink);

        if (appState.token) {
            // Logged In
            const nameSpan = document.createElement('span');
            nameSpan.textContent = `Welcome, ${appState.name}`;
            navLinks.appendChild(nameSpan);

            const manageLink = document.createElement('a');
            manageLink.href = '#';
            manageLink.textContent = 'Manage Profile';
            manageLink.className = 'nav-link';
            manageLink.id = 'nav-manage-profile';
            navLinks.appendChild(manageLink);

            const logoutBtn = document.createElement('button');
            logoutBtn.textContent = 'Logout';
            logoutBtn.className = 'btn btn-logout';
            logoutBtn.id = 'nav-logout-btn';
            navLinks.appendChild(logoutBtn);

        } else {
            // Logged Out
            const loginLink = document.createElement('a');
            loginLink.href = '#';
            loginLink.textContent = 'Login';
            loginLink.className = 'nav-link';
            loginLink.id = 'nav-login-link';
            navLinks.appendChild(loginLink);

            const registerBtn = document.createElement('button');
            registerBtn.textContent = 'Register';
            registerBtn.className = 'btn btn-primary';
            registerBtn.id = 'nav-register-btn';
            navLinks.appendChild(registerBtn);
        }
    }

    /**
     * Updates the local appState object and saves to localStorage
     * @param {object} newState - The new state properties to merge
     */
    function setAppState(newState) {
        appState = { ...appState, ...newState };
        if (newState.token) localStorage.setItem('token', newState.token);
        if (newState.restaurantId) localStorage.setItem('restaurantId', newState.restaurantId);
        if (newState.name) localStorage.setItem('name', newState.name);
        
        if (newState.token === null) {
            localStorage.removeItem('token');
            localStorage.removeItem('restaurantId');
            localStorage.removeItem('name');
            appState = { ...appState, token: null, restaurantId: null, name: null };
        }
        
        updateNavbar();
    }
    
    /**
     * Shows a toast notification with animations
     * @param {string} message - The message to display
     * @param {'success' | 'error'} type - The type of toast
     */
    function showToast(message, type = 'success') {
        const toast = document.createElement('div');
        toast.className = `toast toast-${type}`;
        toast.textContent = message;
        
        toastContainer.appendChild(toast);
        
        // Wait 3 seconds, then add the fade-out class, then remove after animation
        setTimeout(() => {
            toast.classList.add('toast-out');
            toast.addEventListener('animationend', () => {
                toast.remove();
            });
        }, 3000);
    }

    /**
     * Fetches and displays all restaurants
     * Implements: GET /restaurants
     */
    async function loadAllRestaurants() {
        showLoader();
        try {
            const res = await fetch(`${API_BASE_URL}/restaurants`);
            if (!res.ok) throw new Error('Could not fetch restaurants');
            
            const restaurants = await res.json();
            
            restaurantListContainer.innerHTML = ''; // Clear list
            if (restaurants.length === 0) {
                restaurantListContainer.innerHTML = '<p>No restaurants found.</p>';
                return;
            }

            restaurants.forEach(resto => {
                const card = document.createElement('div');
                card.className = 'restaurant-card';
                card.innerHTML = `
                    <h3>${resto.Name}</h3>
                    <p><strong>Location:</strong> ${resto.Location}</p>
                    <p><strong>Phone:</strong> ${resto.Phone}</p>
                    <p><strong>Email:</strong> ${resto.Email}</p>
                `;
                restaurantListContainer.appendChild(card);
            });

        } catch (err) {
            showToast(err.message, 'error');
            restaurantListContainer.innerHTML = '<p>Error loading restaurants.</p>';
        } finally {
            hideLoader();
        }
    }
    
    /**
     * Fetches the current user's profile data and populates the management form
     * Implements: GET /restaurants/:restaurantId
     */
    async function loadProfileData() {
        if (!appState.restaurantId) return;

        showLoader();
        try {
            const res = await fetch(`${API_BASE_URL}/restaurants/${appState.restaurantId}`);
            if (!res.ok) throw new Error('Could not fetch profile data');

            const data = await res.json();
            
            // Populate the form
            welcomeMessage.textContent = `Manage Your Profile, ${data.Name}`;
            mgmtName.value = data.Name;
            mgmtEmail.value = data.Email;
            mgmtLocation.value = data.Location;
            mgmtPhone.value = data.Phone;
            mgmtCommercial.value = data.Commercial_Num;
            mgmtPassword.value = ''; // Clear password field

        } catch (err) {
            showToast(err.message, 'error');
        } finally {
            hideLoader();
        }
    }


    // --- EVENT HANDLERS ---

    /**
     * Handles the login form submission
     * Implements: POST /restaurants/login
     */
    async function handleLogin(e) {
        e.preventDefault();
        showLoader();
        
        const body = {
            email: loginEmail.value,
            password: loginPassword.value
        };

        try {
            const res = await fetch(`${API_BASE_URL}/restaurants/login`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(body)
            });

            const data = await res.json();
            if (!res.ok) throw new Error(data.message || 'Login failed');

            setAppState({
                token: data.token,
                restaurantId: data.restaurantId,
                name: data.name
            });
            
            showPage(managementPage);
            await loadProfileData(); // Load data into the management form

        } catch (err) {
            showToast(err.message, 'error');
        } finally {
            hideLoader();
        }
    }

    /**
     * Handles the registration form submission
     * Implements: POST /restaurants
     */
    async function handleRegister(e) {
        e.preventDefault();
        showLoader();
        
        const body = {
            Name: regName.value,
            Email: regEmail.value,
            Password: regPassword.value,
            Location: regLocation.value,
            Phone: regPhone.value,
            Commercial_Num: regCommercial.value
        };

        try {
            const res = await fetch(`${API_BASE_URL}/restaurants`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(body)
            });

            const data = await res.json();
            if (!res.ok) {
                if (data.errors) throw new Error(data.errors[0].msg);
                throw new Error(data.message || 'Registration failed');
            }

            // Registration was successful, log the user in
            setAppState({
                token: data.token,
                restaurantId: data.restaurant._id,
                name: data.restaurant.Name
            });
            
            showPage(managementPage);
            await loadProfileData();

        } catch (err) {
            showToast(err.message, 'error');
        } finally {
            hideLoader();
        }
    }

    /**
     * Handles the profile update form submission
     * Implements: PATCH /restaurants/:restaurantId
     */
    async function handleUpdateProfile(e) {
        e.preventDefault();
        showLoader();
        
        const updateData = {};
        if (mgmtName.value) updateData.Name = mgmtName.value;
        if (mgmtEmail.value) updateData.Email = mgmtEmail.value;
        if (mgmtLocation.value) updateData.Location = mgmtLocation.value;
        if (mgmtPhone.value) updateData.Phone = mgmtPhone.value;
        if (mgmtCommercial.value) updateData.Commercial_Num = mgmtCommercial.value;
        if (mgmtPassword.value) updateData.Password = mgmtPassword.value;

        if (Object.keys(updateData).length === 0) {
            showToast('No changes to save', 'error');
            hideLoader();
            return;
        }

        try {
            const res = await fetch(`${API_BASE_URL}/restaurants/${appState.restaurantId}`, {
                method: 'PATCH',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${appState.token}`
                },
                body: JSON.stringify(updateData)
            });

            const data = await res.json();
            if (!res.ok) {
                 if (data.errors) throw new Error(data.errors[0].msg);
                throw new Error(data.message || 'Update failed');
            }
            
            showToast('Profile updated successfully!', 'success');
            setAppState({ name: data.Name });
            await loadProfileData();

        } catch (err) {
            showToast(err.message, 'error');
        } finally {
            hideLoader();
        }
    }

    /**
     * Handles the delete account button click
     * Implements: DELETE /restaurants/:restaurantId
     */
    async function handleDeleteAccount() {
        if (!confirm('Are you sure you want to delete your account? This action is permanent and cannot be undone.')) {
            return;
        }
        
        showLoader();
        try {
            const res = await fetch(`${API_BASE_URL}/restaurants/${appState.restaurantId}`, {
                method: 'DELETE',
                headers: {
                    'Authorization': `Bearer ${appState.token}`
                }
            });

            const data = await res.json();
            if (!res.ok) throw new Error(data.message || 'Failed to delete account');

            showToast('Account deleted successfully.', 'success');
            handleLogout(); // Log out and go to login page

        } catch (err) {
            showToast(err.message, 'error');
        } finally {
            hideLoader();
        }
    }
    
    /**
     * Handles logout button click
     */
    function handleLogout() {
        setAppState({ token: null });
        showPage(loginPage);
        loginForm.reset();
        registerForm.reset();
    }


    // --- EVENT LISTENERS ---
    
    // Form Submissions
    loginForm.addEventListener('submit', handleLogin);
    registerForm.addEventListener('submit', handleRegister);
    managementForm.addEventListener('submit', handleUpdateProfile);
    
    // Page Navigation (Static Links)
    showRegisterLink.addEventListener('click', (e) => {
        e.preventDefault();
        showPage(registerPage);
    });
    showLoginLink.addEventListener('click', (e) => {
        e.preventDefault();
        showPage(loginPage);
    });
    
    // Page Navigation (Dynamic Links in Navbar)
    navLinks.addEventListener('click', (e) => {
        e.preventDefault();
        const targetId = e.target.id;
        
        if (targetId === 'nav-logout-btn') {
            handleLogout();
        }
        if (targetId === 'nav-login-link') {
            showPage(loginPage);
        }
        if (targetId === 'nav-register-btn') {
            showPage(registerPage);
        }
        if (targetId === 'nav-all-restaurants') {
            showPage(allRestaurantsPage);
            loadAllRestaurants();
        }
        if (targetId === 'nav-manage-profile') {
            showPage(managementPage);
            loadProfileData();
        }
    });
    
    // Other Buttons
    deleteAccountBtn.addEventListener('click', handleDeleteAccount);

    // --- INITIALIZATION ---
    function init() {
        updateNavbar();
        if (appState.token) {
            showPage(managementPage);
            loadProfileData();
        } else {
            showPage(loginPage);
        }
    }

    init();

});
