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

use App\Http\Controllers\Api\Admin\AdminDashboardController;
use App\Http\Controllers\Api\Admin\AdminApplicantController;
use App\Http\Controllers\Api\Admin\AdminEventController;
use App\Http\Controllers\Api\Admin\AdminUserController;
use App\Http\Controllers\Api\Admin\AdminProfileController;
use App\Http\Controllers\Api\Admin\AdminEmployerVerificationController;
use App\Http\Controllers\Api\Admin\AdminReportController;
use App\Http\Controllers\Api\Admin\AdminArchiveController;
use App\Http\Controllers\Api\Admin\AdminAuditLogController;

use App\Http\Controllers\Api\Employer\EmployerDashboardController;
use App\Http\Controllers\Api\Employer\EmployerJobController;
use App\Http\Controllers\Api\Employer\EmployerApplicantController;
use App\Http\Controllers\Api\Employer\EmployerProfileController;

use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| PUBLIC ROUTES
|--------------------------------------------------------------------------
*/

// Applicant auth
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

// PESO employee login
Route::post('/peso-employee/login', [PesoEmployeeAuthController::class, 'login']);

// Employer auth
Route::post('/employer/login', [EmployerAuthController::class, 'login']);
Route::post('/employer/register', [EmployerAuthController::class, 'register']);
Route::post('/employer/forgot-password', [EmployerAuthController::class, 'forgotPassword']);
Route::post('/employer/reset-password', [EmployerAuthController::class, 'resetPassword']);

// Resume public viewing
Route::get('/resume/view', [AuthController::class, 'viewResumeByToken']);

// Locations
Route::get('/locations/provinces', [LocationController::class, 'getProvinces']);
Route::get('/locations/cities/{provinceId}', [LocationController::class, 'getCities']);
Route::get('/locations/barangays/{cityId}', [LocationController::class, 'getBarangays']);
Route::get('/locations/all', [LocationController::class, 'getAllLocations']);

// Jobs
Route::get('/jobs', [JobListingController::class, 'index']);
Route::get('/jobs/{id}', [JobListingController::class, 'show']);
Route::get('/jobs-skills/catalog', [JobListingController::class, 'skillCatalog']);

// Events
Route::get('/events', [EventController::class, 'index']);

// Employers
Route::get('/employers', [EmployerController::class, 'index']);
Route::get('/employers/{id}', [EmployerController::class, 'show']);


/*
|--------------------------------------------------------------------------
| APPLICANT ROUTES
|--------------------------------------------------------------------------
*/

Route::middleware('auth:sanctum')->group(function () {

    Route::get('/user', [AuthController::class, 'user']);
    Route::put('/user/profile', [AuthController::class, 'updateProfile']);
    Route::put('/user/skills', [AuthController::class, 'updateSkills']);

    // Resume
    Route::post('/user/resume', [AuthController::class, 'uploadResume']);
    Route::get('/user/resume', [AuthController::class, 'downloadResume']);
    Route::get('/user/resume/view-url', [AuthController::class, 'resumeViewUrl']);

    // Avatar
    Route::post('/user/avatar', [AuthController::class, 'uploadAvatar']);
    Route::get('/user/avatar', [AuthController::class, 'getAvatar']);

    Route::post('/logout', [AuthController::class, 'logout']);

    // Applications
    Route::get('/applications', [ApplicationController::class, 'index']);
    Route::post('/applications', [ApplicationController::class, 'store']);

    // Saved jobs
    Route::get('/saved-jobs', [SavedJobController::class, 'index']);
    Route::post('/saved-jobs', [SavedJobController::class, 'store']);
    Route::delete('/saved-jobs/{jobListing}', [SavedJobController::class, 'destroy']);

    // Job matching
    Route::get('/jobs-matched', [JobListingController::class, 'matched']);
});


/*
|--------------------------------------------------------------------------
| ADMIN / PESO EMPLOYEE ROUTES
|--------------------------------------------------------------------------
*/

Route::middleware(['auth:sanctum', \App\Http\Middleware\EnsurePesoEmployee::class])->group(function () {

    Route::post('/peso-employee/logout', [PesoEmployeeAuthController::class, 'logout']);
    Route::get('/peso-employee/me', [PesoEmployeeAuthController::class, 'user']);

    // Dashboard
    Route::get('/admin/dashboard', [AdminDashboardController::class, 'index']);

    // Applicants
    Route::get('/admin/applicants', [AdminApplicantController::class, 'index']);
    Route::get('/admin/applicants/{id}', [AdminApplicantController::class, 'show']);
    Route::patch('/admin/applicants/{id}/status', [AdminApplicantController::class, 'updateStatus']);
    Route::post('/admin/applicants/{id}/archive', [AdminApplicantController::class, 'archive']);
    Route::post('/admin/applicants/{id}/files/{type}', [AdminApplicantController::class, 'uploadFile']);

    // Events
    Route::get('/admin/events', [AdminEventController::class, 'index']);
    Route::post('/admin/events', [AdminEventController::class, 'store']);
    Route::get('/admin/events/{id}', [AdminEventController::class, 'show']);
    Route::put('/admin/events/{id}', [AdminEventController::class, 'update']);
    Route::delete('/admin/events/{id}', [AdminEventController::class, 'destroy']);

    // Staff users
    Route::get('/admin/users', [AdminUserController::class, 'index']);
    Route::post('/admin/users', [AdminUserController::class, 'store']);
    Route::get('/admin/users/{id}', [AdminUserController::class, 'show']);
    Route::put('/admin/users/{id}', [AdminUserController::class, 'update']);
    Route::delete('/admin/users/{id}', [AdminUserController::class, 'destroy']);

    // Profile
    Route::get('/admin/profile', [AdminProfileController::class, 'show']);
    Route::put('/admin/profile', [AdminProfileController::class, 'update']);
    Route::post('/admin/profile/password', [AdminProfileController::class, 'changePassword']);

    // Employers
    Route::post('/employers', [EmployerController::class, 'store']);
    Route::put('/employers/{id}', [EmployerController::class, 'update']);
    Route::delete('/employers/{id}', [EmployerController::class, 'destroy']);
    Route::post('/employers/{id}/verify-email', [EmployerController::class, 'verifyEmail']);

    // Employer verification
    Route::get('/admin/employer-verifications', [AdminEmployerVerificationController::class, 'index']);
    Route::get('/admin/employer-verifications/{id}', [AdminEmployerVerificationController::class, 'show']);
    Route::patch('/admin/employer-verifications/{id}/verify', [AdminEmployerVerificationController::class, 'verify']);
    Route::patch('/admin/employer-verifications/{id}/reject', [AdminEmployerVerificationController::class, 'reject']);
    Route::patch('/admin/employer-verifications/{id}/revoke', [AdminEmployerVerificationController::class, 'revoke']);

    // Reports
    Route::post('/admin/reports/generate', [AdminReportController::class, 'generate']);

    // Archive
    Route::get('/admin/archive', [AdminArchiveController::class, 'index']);
    Route::post('/admin/archive/{type}/{id}/restore', [AdminArchiveController::class, 'restore']);
    Route::delete('/admin/archive/{type}/{id}', [AdminArchiveController::class, 'forceDelete']);
    Route::delete('/admin/archive', [AdminArchiveController::class, 'clearAll']);
    Route::delete('/admin/archive/{type}', [AdminArchiveController::class, 'clearAll']);

    // Audit logs
    Route::get('/admin/audit-logs', [AdminAuditLogController::class, 'index']);
});


/*
|--------------------------------------------------------------------------
| EMPLOYER ROUTES
|--------------------------------------------------------------------------
*/

Route::middleware(['auth:sanctum', \App\Http\Middleware\EnsureEmployer::class])->group(function () {

    Route::post('/employer/logout', [EmployerAuthController::class, 'logout']);
    Route::get('/employer/me', [EmployerAuthController::class, 'user']);

    Route::get('/employer/dashboard', [EmployerDashboardController::class, 'index']);

    Route::get('/employer/jobs', [EmployerJobController::class, 'index']);
    Route::post('/employer/jobs', [EmployerJobController::class, 'store']);
    Route::get('/employer/jobs/{id}', [EmployerJobController::class, 'show']);
    Route::put('/employer/jobs/{id}', [EmployerJobController::class, 'update']);
    Route::patch('/employer/jobs/{id}/close', [EmployerJobController::class, 'close']);
    Route::delete('/employer/jobs/{id}', [EmployerJobController::class, 'destroy']);

    Route::get('/employer/applicants', [EmployerApplicantController::class, 'index']);
    Route::get('/employer/applicants/{id}', [EmployerApplicantController::class, 'show']);
    Route::patch('/employer/applicants/{id}/status', [EmployerApplicantController::class, 'updateStatus']);

    Route::get('/employer/profile', [EmployerProfileController::class, 'show']);
    Route::put('/employer/profile', [EmployerProfileController::class, 'update']);
    Route::put('/employer/profile/company', [EmployerProfileController::class, 'updateCompany']);
    Route::post('/employer/profile/password', [EmployerProfileController::class, 'changePassword']);
});