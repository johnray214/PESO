<?php

namespace App\Http\Controllers\Api\Auth;

use App\Http\Controllers\Controller;
use App\Models\Jobseeker;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class JobseekerAuthController extends Controller
{
    public function register(Request $request)
    {
        $validated = $request->validate([
            'first_name' => 'required|string|max:100',
            'last_name' => 'required|string|max:100',
            'email' => 'required|email|unique:jobseekers|max:191',
            'password' => 'required|string|min:8|confirmed',
            'contact' => 'nullable|string|max:20',
            'address' => 'nullable|string|max:255',
            'sex' => 'nullable|in:male,female',
            'date_of_birth' => 'nullable|date',
        ]);

        $validated['password'] = Hash::make($validated['password']);
        $validated['status'] = 'active';

        $jobseeker = Jobseeker::create($validated);

        $token = $jobseeker->createToken('jobseeker-token')->plainTextToken;

        return response()->json([
            'success' => true,
            'data' => [
                'jobseeker' => $jobseeker,
                'token' => $token,
            ],
            'message' => 'Registration successful. Please verify your email.',
        ], 201);
    }

    public function login(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required|string',
        ]);

        $jobseeker = Jobseeker::where('email', $request->email)->first();

        if (!$jobseeker || !Hash::check($request->password, $jobseeker->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid credentials',
            ], 401);
        }

        $token = $jobseeker->createToken('jobseeker-token')->plainTextToken;

        return response()->json([
            'success' => true,
            'data' => [
                'jobseeker' => $jobseeker,
                'token' => $token,
            ],
            'message' => 'Login successful',
        ]);
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'success' => true,
            'message' => 'Logged out successfully',
        ]);
    }

    public function me(Request $request)
    {
        return response()->json([
            'success' => true,
            'data' => $request->user()->load('skills'),
        ]);
    }

    public function verifyEmail($id, $hash)
    {
        $jobseeker = Jobseeker::findOrFail($id);

        if ($jobseeker->hasVerifiedEmail()) {
            return response()->json([
                'success' => false,
                'message' => 'Email already verified',
            ], 400);
        }

        $jobseeker->update(['email_verified_at' => now()]);

        return response()->json([
            'success' => true,
            'message' => 'Email verified successfully',
        ]);
    }
}
