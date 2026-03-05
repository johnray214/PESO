<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\LocationController;
use App\Http\Controllers\Api\JobListingController;
use App\Http\Controllers\Api\EventController;
use App\Http\Controllers\Api\ApplicationController;
use App\Http\Controllers\Api\SavedJobController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

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
