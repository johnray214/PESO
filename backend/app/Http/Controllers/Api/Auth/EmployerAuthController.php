<?php

namespace App\Http\Controllers\Api\Auth;

use App\Http\Controllers\Controller;
use App\Models\Employer;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;

class EmployerAuthController extends Controller
{
    public function register(Request $request)
    {
        $validated = $request->validate([
            'company_name' => 'required|string|max:255',
            'contact_person' => 'required|string|max:255',
            'email' => 'required|email|unique:employers|max:191',
            'password' => 'required|string|min:8|confirmed',
            'industry' => 'required|string|max:100',
            'company_size' => 'required|string|max:30',
            'city' => 'required|string|max:100',
            'phone' => 'required|string|max:20',
            'tin' => 'nullable|string|max:50',
            'website' => 'nullable|string|max:255',
            'latitude' => 'nullable|numeric',
            'longitude' => 'nullable|numeric',
            'address_full' => 'nullable|string|max:255',
            'biz_permit' => 'nullable|file|mimes:pdf,jpg,jpeg,png|max:5120',
            'bir_cert' => 'nullable|file|mimes:pdf,jpg,jpeg,png|max:5120',
        ]);

        $validated['password'] = Hash::make($validated['password']);
        $validated['status'] = 'pending';

        // Handle file uploads
        if ($request->hasFile('biz_permit')) {
            $tempPath = $request->file('biz_permit')->store('temp', 'public');
            $validated['biz_permit_path'] = $tempPath;
        }

        if ($request->hasFile('bir_cert')) {
            $tempPath = $request->file('bir_cert')->store('temp', 'public');
            $validated['bir_cert_path'] = $tempPath;
        }

        $employer = Employer::create($validated);

        // Move files to proper directory
        if ($request->hasFile('biz_permit')) {
            $newPath = "employer-docs/{$employer->id}/biz_permit." . $request->file('biz_permit')->extension();
            Storage::disk('public')->move($validated['biz_permit_path'], $newPath);
            $employer->update(['biz_permit_path' => $newPath]);
        }

        if ($request->hasFile('bir_cert')) {
            $newPath = "employer-docs/{$employer->id}/bir_cert." . $request->file('bir_cert')->extension();
            Storage::disk('public')->move($validated['bir_cert_path'], $newPath);
            $employer->update(['bir_cert_path' => $newPath]);
        }

        $token = $employer->createToken('employer-token')->plainTextToken;

        return response()->json([
            'success' => true,
            'data' => [
                'employer' => $employer,
                'token' => $token,
            ],
            'message' => 'Registration successful. Your account is pending for verification.',
        ], 201);
    }

    public function login(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required|string',
        ]);

        $employer = Employer::where('email', $request->email)->first();

        if (!$employer || !Hash::check($request->password, $employer->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid credentials',
            ], 401);
        }

        if ($employer->status !== 'verified'){
            return response()->json([
                'success' => false,
                'message' => 'Your account is not verified yet.',
            ], 403);
        }

        $token = $employer->createToken('employer-token')->plainTextToken;

        return response()->json([
            'success' => true,
            'data' => [
                'employer' => $employer,
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
            'data' => $request->user(),
        ]);
    }
}
