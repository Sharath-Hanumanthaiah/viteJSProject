# Eminence Hub - Event Registration Portal

A full-stack, component-based web application for managing event registrations. Built with a modern, premium UI focusing on dark mode glassmorphism aesthetics, utilizing React, Vite, and Tailwind CSS. The backend is powered by Express.js with an in-memory database to store users, events, and registrations.

## Features

- **User Authentication**: Secure Sign Up and Sign In pages with form validation.
- **Dashboard (Home)**: View active events and register attendees. Includes date-validation rules (registrations are only permitted if the current date falls between the event's start and end dates).
- **Event Management**: Create new events with titles, descriptions, locations, start dates, and end dates.
- **Premium UI/UX**: Designed with a sophisticated dark mode palette, glassmorphism (`backdrop-blur`), smooth micro-animations, and Radix UI-inspired custom components.
- **Responsive Layout**: Fully responsive design for desktop, tablet, and mobile viewing.
- **In-Memory Store**: A lightweight Express backend that stores users, events, and registrations in memory for quick demonstration and testing.

## Technology Stack

### Frontend
- **Framework**: React 19, Vite
- **Routing**: React Router DOM
- **Styling**: Tailwind CSS (v3), PostCSS, Autoprefixer
- **Icons**: Lucide React
- **Typography**: Google Fonts (Inter)

### Backend
- **Server**: Express.js, Node.js
- **Middleware**: CORS, Morgan (for logging)
- **Database**: Custom in-memory store (`store.js`)
- **Development**: Nodemon, Concurrently (to run frontend and backend together)

## Project Structure

```
viteJSProject/
├── package.json             # Root dependencies and scripts (concurrently dev script)
├── backend/                 # Express backend directory
│   ├── server.js            # Main Express server and API endpoints
│   └── data/
│       └── store.js         # In-memory database with pre-populated dummy data
└── src/                     # React frontend directory
    ├── components/          # Reusable UI components (Navbar, ProtectedRoute)
    │   └── ui/              # Base UI elements (Button, Input, Card)
    ├── pages/               # Main application views (Home, Events, SignIn, SignUp)
    ├── utils/               # Helper utilities (api.js for API calls and auth state)
    ├── App.jsx              # Routing configuration
    ├── main.jsx             # React entry point
    └── index.css            # Global Tailwind CSS and custom glassmorphism styles
```

## Getting Started

### Prerequisites

Ensure you have [Node.js](https://nodejs.org/) installed on your machine.

### Installation

1. Navigate to the project root directory:
   ```bash
   cd path/to/viteJSProject
   ```

2. Install all dependencies (frontend and backend packages are managed from the root `package.json`):
   ```bash
   npm install
   ```

### Running the Application

Start both the Vite frontend development server and the Express backend server concurrently using a single command:

```bash
npm run dev
```

This will:
- Start the React frontend on `http://localhost:5173`
- Start the Express backend on `http://localhost:5001`
- Any frontend API requests to `/api/*` are automatically proxied to the backend.

### Testing the Features

1. **Sign Up / Sign In**: Open `http://localhost:5173`. You will be redirected to the sign-in page. You can use the mock user `john@example.com` / `password123` or create a new account via the Sign Up page.
2. **Dashboard**: Once logged in, view the registrations list.
3. **Manage Events**: Navigate to "Events Setup" from the Navbar to create new events with specific start and end dates.
4. **Register Attendees**: Back on the Dashboard, select an active event from the dropdown. You can only register an attendee if the current date is within the event's start and end date range.

## Design Aesthetic Details

The application features:
- **Colors**: Deep slates (`#0b0f19`), rich indigos, and vivid violet accents.
- **Glassmorphism**: Elegant translucent cards utilizing `bg-white/5` and `backdrop-blur-md` for a premium feel.
- **Animations**: Subtle fade-ins, glowing button hover effects, and animated ambient background bubbles.
