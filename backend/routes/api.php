<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\PesoEmployeeAuthController;
use App\Http\Controllers\Api\EmployerAuthController;
use App\Http\Controllers\Api\LocationController;
use App\Http\Controllers\Api\JobListingController;
use App\Http\Controllers\Api\EventController;
use App\Http\Controllers\Api\ApplicationController;
use App\Http\Controllers\Api\SavedJobController;
use App\Http\Controllers\Api\EmployerController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

// PESO employee (admin dashboard) login — email + password, role from DB
Route::post('/peso-employee/login', [PesoEmployeeAuthController::class, 'login']);
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/peso-employee/logout', [PesoEmployeeAuthController::class, 'logout']);
    Route::get('/peso-employee/me', [PesoEmployeeAuthController::class, 'user']);
});

// Employer authentication
Route::post('/employer/login', [EmployerAuthController::class, 'login']);
Route::post('/employer/register', [EmployerAuthController::class, 'register']);
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/employer/logout', [EmployerAuthController::class, 'logout']);
    Route::get('/employer/me', [EmployerAuthController::class, 'user']);
});

Route::get('/locations/provinces', [LocationController::class, 'getProvinces']);
Route::get('/locations/cities/{provinceId}', [LocationController::class, 'getCities']);
Route::get('/locations/barangays/{cityId}', [LocationController::class, 'getBarangays']);
Route::get('/locations/all', [LocationController::class, 'getAllLocations']);

// Job listings — public (no auth required to browse jobs)
Route::get('/jobs', [JobListingController::class, 'index']);
Route::get('/jobs/{id}', [JobListingController::class, 'show']);
Route::get('/jobs-skills/catalog', [JobListingController::class, 'skillCatalog']);

// Events — public (job fairs, seminars, career events)
Route::get('/events', [EventController::class, 'index']);

// Employers — API endpoints
Route::get('/employers', [EmployerController::class, 'index']);
Route::get('/employers/{id}', [EmployerController::class, 'show']);
Route::post('/employers', [EmployerController::class, 'store']);
Route::put('/employers/{id}', [EmployerController::class, 'update']);
Route::delete('/employers/{id}', [EmployerController::class, 'destroy']);
Route::post('/employers/{id}/verify-email', [EmployerController::class, 'verifyEmail']);

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/user', [AuthController::class, 'user']);
    Route::put('/user/profile', [AuthController::class, 'updateProfile']);
    Route::put('/user/skills', [AuthController::class, 'updateSkills']);
    Route::post('/logout', [AuthController::class, 'logout']);

    // Job applications
    Route::get('/applications', [ApplicationController::class, 'index']);
    Route::post('/applications', [ApplicationController::class, 'store']);

    // Saved jobs
    Route::get('/saved-jobs', [SavedJobController::class, 'index']);
    Route::post('/saved-jobs', [SavedJobController::class, 'store']);
    Route::delete('/saved-jobs/{jobListing}', [SavedJobController::class, 'destroy']);

    // Skill-matched jobs
    Route::get('/jobs-matched', [JobListingController::class, 'matched']);
});
