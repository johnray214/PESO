<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\LocationController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

Route::get('/locations/provinces', [LocationController::class, 'getProvinces']);
Route::get('/locations/cities/{provinceId}', [LocationController::class, 'getCities']);
Route::get('/locations/barangays/{cityId}', [LocationController::class, 'getBarangays']);
Route::get('/locations/all', [LocationController::class, 'getAllLocations']);

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/user', [AuthController::class, 'user']);
    Route::post('/logout', [AuthController::class, 'logout']);
});
