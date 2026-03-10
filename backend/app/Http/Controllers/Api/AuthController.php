<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|min:3|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:6|confirmed',
            'age' => 'nullable|integer|min:15|max:120',
            'gender' => 'nullable|in:Male,Female,Other',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        $user = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'password' => Hash::make($request->password),
            'age' => $request->age,
            'gender' => $request->gender,
        ]);

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'User registered successfully',
            'data' => [
                'user' => $user,
                'token' => $token
            ]
        ], 201);
    }

    public function login(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|string|email',
            'password' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        if (!Auth::attempt($request->only('email', 'password'))) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid credentials'
            ], 401);
        }

        $user = User::where('email', $request->email)->firstOrFail();
        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Login successful',
            'data' => [
                'user' => $user,
                'token' => $token
            ]
        ], 200);
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'success' => true,
            'message' => 'Logged out successfully'
        ], 200);
    }

    public function user(Request $request)
    {
        return response()->json([
            'success' => true,
            'data' => $request->user()
        ], 200);
    }

    public function updateProfile(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name'    => 'sometimes|string|min:2|max:255',
            'email'   => 'sometimes|string|email|max:255|unique:users,email,' . $request->user()->id,
            'phone'   => 'nullable|string|max:20',
            'address' => 'nullable|string|max:500',
            'age'     => 'nullable|integer|min:15|max:120',
            'gender'  => 'nullable|in:Male,Female,Other',
            'skills'  => 'nullable|array',
            'skills.*' => 'string|max:100',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors'  => $validator->errors(),
            ], 422);
        }

        $user = $request->user();
        $user->update($request->only(['name', 'email', 'phone', 'address', 'age', 'gender', 'skills']));

        return response()->json([
            'success' => true,
            'message' => 'Profile updated successfully',
            'data'    => $user->fresh(),
        ], 200);
    }

    public function updateSkills(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'skills'   => 'required|array',
            'skills.*' => 'string|max:100',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors'  => $validator->errors(),
            ], 422);
        }

        $user = $request->user();
        $user->update(['skills' => $request->skills]);

        return response()->json([
            'success' => true,
            'message' => 'Skills updated successfully',
            'data'    => $user->fresh(),
        ], 200);
    }

    public function uploadResume(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'resume' => 'required|file|mimes:pdf|max:5120',
        ], [
            'resume.required' => 'Please select a PDF file.',
            'resume.mimes'    => 'The resume must be a PDF file.',
            'resume.max'      => 'The resume must not exceed 5MB.',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors'  => $validator->errors(),
            ], 422);
        }

        $user = $request->user();
        $file = $request->file('resume');

        // Delete previous resume if any
        if ($user->resume_path && Storage::disk('local')->exists($user->resume_path)) {
            Storage::disk('local')->delete($user->resume_path);
        }

        $path = $file->store('resumes/' . $user->id, 'local');
        $user->update(['resume_path' => $path]);

        return response()->json([
            'success' => true,
            'message' => 'Resume uploaded successfully',
            'data'    => ['resume_path' => $path],
        ], 200);
    }

    public function uploadAvatar(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'avatar' => 'required|image|mimes:jpeg,png,jpg,gif|max:2048',
        ], [
            'avatar.required' => 'Please select an image.',
            'avatar.image'    => 'The file must be an image.',
            'avatar.mimes'    => 'The image must be JPEG, PNG, JPG, or GIF.',
            'avatar.max'      => 'The image must not exceed 2MB.',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors'  => $validator->errors(),
            ], 422);
        }

        $user = $request->user();
        $file = $request->file('avatar');

        if ($user->avatar_path && Storage::disk('local')->exists($user->avatar_path)) {
            Storage::disk('local')->delete($user->avatar_path);
        }

        $path = $file->store('avatars/' . $user->id, 'local');
        $user->update(['avatar_path' => $path]);

        return response()->json([
            'success' => true,
            'message' => 'Profile picture updated',
            'data'    => ['avatar_path' => $path],
        ], 200);
    }

    public function getAvatar(Request $request)
    {
        $user = $request->user();
        if (!$user->avatar_path) {
            return response()->json(['message' => 'No avatar'], 404);
        }
        if (!Storage::disk('local')->exists($user->avatar_path)) {
            return response()->json(['message' => 'Avatar not found'], 404);
        }
        $path = Storage::disk('local')->path($user->avatar_path);
        $contents = file_get_contents($path);
        $ext = strtolower(pathinfo($user->avatar_path, PATHINFO_EXTENSION));
        $mime = match ($ext) {
            'png' => 'image/png',
            'gif' => 'image/gif',
            default => 'image/jpeg',
        };
        return response()->make($contents, 200, [
            'Content-Type'   => $mime,
            'Content-Length' => (string) strlen($contents),
        ]);
    }

    public function downloadResume(Request $request)
    {
        $user = $request->user();
        if (!$user->resume_path) {
            return response()->json(['success' => false, 'message' => 'No resume on file'], 404);
        }
        if (!Storage::disk('local')->exists($user->resume_path)) {
            return response()->json(['success' => false, 'message' => 'Resume file not found'], 404);
        }
        $path = Storage::disk('local')->path($user->resume_path);
        $contents = file_get_contents($path);
        $filename = basename($user->resume_path);
        return response()->make($contents, 200, [
            'Content-Type'        => 'application/pdf',
            'Content-Disposition' => 'inline; filename="' . $filename . '"',
            'Content-Length'      => (string) strlen($contents),
        ]);
    }

    /**
     * Generate a one-time URL to view the resume (opens in browser, no auth in request).
     */
    public function resumeViewUrl(Request $request)
    {
        $user = $request->user();
        if (!$user->resume_path) {
            return response()->json(['success' => false, 'message' => 'No resume on file'], 404);
        }
        if (!Storage::disk('local')->exists($user->resume_path)) {
            return response()->json(['success' => false, 'message' => 'Resume file not found'], 404);
        }
        $token = Str::random(64);
        Cache::put('resume_view:' . $token, $user->id, now()->addMinutes(10));
        $url = $request->getSchemeAndHttpHost() . '/api/resume/view?t=' . $token;
        return response()->json([
            'success' => true,
            'url'     => $url,
        ], 200);
    }

    /**
     * Serve resume PDF by one-time token (public route, no auth).
     */
    public function viewResumeByToken(Request $request)
    {
        $token = $request->query('t');
        if (!$token) {
            return response()->json(['message' => 'Missing token'], 400);
        }
        $userId = Cache::get('resume_view:' . $token);
        if (!$userId) {
            return response()->json(['message' => 'Invalid or expired link'], 404);
        }
        Cache::forget('resume_view:' . $token);
        $user = User::find($userId);
        if (!$user || !$user->resume_path) {
            return response()->json(['message' => 'Resume not found'], 404);
        }
        if (!Storage::disk('local')->exists($user->resume_path)) {
            return response()->json(['message' => 'File not found'], 404);
        }
        $path = Storage::disk('local')->path($user->resume_path);
        $contents = file_get_contents($path);
        $filename = basename($user->resume_path);
        return response()->make($contents, 200, [
            'Content-Type'        => 'application/pdf',
            'Content-Disposition' => 'inline; filename="' . $filename . '"',
            'Content-Length'      => (string) strlen($contents),
        ]);
    }
}
