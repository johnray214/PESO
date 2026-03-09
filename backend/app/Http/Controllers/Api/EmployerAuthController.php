<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Employer;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;

class EmployerAuthController extends Controller
{
    public function login(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email',
            'password' => 'required',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $employer = Employer::where('email', $request->email)->first();

        if (!$employer || !Hash::check($request->password, $employer->password)) {
            return response()->json(['message' => 'Invalid credentials'], 401);
        }

        if ($employer->status !== 'active') {
            return response()->json(['message' => 'Your account is not active. Please contact PESO.'], 403);
        }

        $token = $employer->createToken('employer-token')->plainTextToken;

        return response()->json([
            'token' => $token,
            'employer' => [
                'id' => $employer->id,
                'company_name' => $employer->company_name,
                'email' => $employer->email,
                'industry' => $employer->industry,
                'contact' => $employer->contact,
                'contact_person' => $employer->contact_person,
                'status' => $employer->status,
                'total_hired' => $employer->total_hired,
                'email_verified' => $employer->email_verified_at ? true : false,
            ],
        ]);
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();
        return response()->json(['message' => 'Logged out successfully']);
    }

    public function user(Request $request)
    {
        $employer = $request->user();
        return response()->json([
            'id' => $employer->id,
            'company_name' => $employer->company_name,
            'email' => $employer->email,
            'industry' => $employer->industry,
            'contact' => $employer->contact,
            'contact_person' => $employer->contact_person,
            'status' => $employer->status,
            'total_hired' => $employer->total_hired,
            'email_verified' => $employer->email_verified_at ? true : false,
        ]);
    }

    public function register(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'company_name' => 'required|string|max:255',
            'email' => 'required|email|unique:employers,email',
            'password' => 'required|string|min:6|confirmed',
            'industry' => 'nullable|string|max:255',
            'contact' => 'nullable|string|max:255',
            'contact_person' => 'nullable|string|max:255',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $employer = Employer::create([
            'company_name' => $request->company_name,
            'email' => $request->email,
            'password' => Hash::make($request->password),
            'industry' => $request->industry,
            'contact' => $request->contact,
            'contact_person' => $request->contact_person,
            'status' => 'pending',
        ]);

        $token = $employer->createToken('employer-token')->plainTextToken;

        return response()->json([
            'message' => 'Registration successful. Your account is pending approval.',
            'token' => $token,
            'employer' => [
                'id' => $employer->id,
                'company_name' => $employer->company_name,
                'email' => $employer->email,
                'status' => $employer->status,
            ],
        ], 201);
    }
}
