// src/services/api.js
import axios from "axios";

// Create axios instance
const api = axios.create({
   baseURL: 'http://127.0.0.1:8000/api',
   timeout: 60000,
   headers: {
      Accept: 'application/json',
   },
});

// Request interceptor → attach token
api.interceptors.request.use(
    (config) => {
        const token = localStorage.getItem("auth_token");
        if (token) {
            config.headers.Authorization = `Bearer ${token}`;
        }
        return config;
    },
    (error) => Promise.reject(error)
);
