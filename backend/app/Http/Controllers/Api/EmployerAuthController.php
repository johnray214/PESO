<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AuditLog;
use App\Models\Employer;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Password;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;

class EmployerAuthController extends Controller
{
    public function login(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email'    => 'required|email',
            'password' => 'required',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $employer = Employer::where('email', $request->email)->first();

        if (!$employer || !Hash::check($request->password, $employer->password)) {
            return response()->json(['message' => 'Invalid credentials'], 401);
        }

        if ($employer->status === 'inactive') {
            return response()->json(['message' => 'Your account has been deactivated. Please contact PESO.'], 403);
        }

        $token = $employer->createToken('employer-token')->plainTextToken;

        AuditLog::record('Logged In', 'System', "Employer {$employer->company_name} logged in", $request, $employer);

        return response()->json([
            'token'    => $token,
            'employer' => $this->formatEmployer($employer),
        ]);
    }

    public function register(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'first_name'    => 'required|string|max:100',
            'last_name'     => 'required|string|max:100',
            'email'         => 'required|email|unique:employers,email',
            'password'      => 'required|string|min:6|confirmed',
            'company_name'  => 'required|string|max:255',
            'industry'      => 'nullable|string|max:100',
            'company_size'  => 'nullable|string|max:50',
            'city'          => 'nullable|string|max:100',
            'phone'         => 'nullable|string|max:20',
            'tin'           => 'nullable|string|max:50',
            'website'       => 'nullable|url|max:255',
            'biz_permit'    => 'required|file|mimes:pdf,jpg,jpeg,png|max:5120',
            'bir_cert'      => 'nullable|file|mimes:pdf,jpg,jpeg,png|max:5120',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $bizPermitUrl = null;
        if ($request->hasFile('biz_permit')) {
            $path = $request->file('biz_permit')->store('employer_docs', 'public');
            $bizPermitUrl = Storage::url($path);
        }

        $birCertUrl = null;
        if ($request->hasFile('bir_cert')) {
            $path = $request->file('bir_cert')->store('employer_docs', 'public');
            $birCertUrl = Storage::url($path);
        }

        $employer = Employer::create([
            'first_name'          => $request->first_name,
            'last_name'           => $request->last_name,
            'contact_person'      => "{$request->first_name} {$request->last_name}",
            'company_name'        => $request->company_name,
            'email'               => $request->email,
            'password'            => Hash::make($request->password),
            'industry'            => $request->industry,
            'company_size'        => $request->company_size,
            'city'                => $request->city,
            'contact'             => $request->phone,
            'tin'                 => $request->tin,
            'website'             => $request->website,
            'biz_permit_url'      => $bizPermitUrl,
            'bir_cert_url'        => $birCertUrl,
            'status'              => 'pending',
            'verification_status' => 'pending',
        ]);

        $token = $employer->createToken('employer-token')->plainTextToken;

        return response()->json([
            'message'  => 'Registration successful. Your account is pending approval.',
            'token'    => $token,
            'employer' => $this->formatEmployer($employer),
        ], 201);
    }

    public function logout(Request $request)
    {
        $employer = $request->user();
        AuditLog::record('Logged In', 'System', "Employer {$employer->company_name} logged out", $request, $employer);
        $request->user()->currentAccessToken()->delete();
        return response()->json(['message' => 'Logged out successfully']);
    }

    public function user(Request $request)
    {
        return response()->json(['employer' => $this->formatEmployer($request->user())]);
    }

    public function forgotPassword(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $employer = Employer::where('email', $request->email)->first();

        // Always return success to prevent email enumeration
        if (!$employer) {
            return response()->json([
                'success' => true,
                'message' => 'If that email exists, a reset link has been sent.',
            ]);
        }

        // Generate a reset token and store it
        $token = Str::random(64);

        \DB::table('employer_password_resets')->updateOrInsert(
            ['email' => $employer->email],
            ['token' => Hash::make($token), 'created_at' => now()]
        );

        // In production, send an email with the reset link
        // Mail::to($employer->email)->send(new EmployerPasswordResetMail($token));

        return response()->json([
            'success' => true,
            'message' => 'If that email exists, a reset link has been sent.',
            // Only include token in development — remove in production
            '_dev_token' => config('app.debug') ? $token : null,
        ]);
    }

    public function resetPassword(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email'    => 'required|email',
            'token'    => 'required|string',
            'password' => 'required|string|min:6|confirmed',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $record = \DB::table('employer_password_resets')
            ->where('email', $request->email)
            ->first();

        if (!$record || !Hash::check($request->token, $record->token)) {
            return response()->json(['message' => 'Invalid or expired reset token'], 422);
        }

        if (now()->diffInMinutes($record->created_at) > 30) {
            return response()->json(['message' => 'Reset token has expired'], 422);
        }

        $employer = Employer::where('email', $request->email)->firstOrFail();
        $employer->update(['password' => Hash::make($request->password)]);

        \DB::table('employer_password_resets')->where('email', $request->email)->delete();

        return response()->json(['success' => true, 'message' => 'Password reset successfully']);
    }

    private function formatEmployer(Employer $employer): array
    {
        return [
            'id'                 => $employer->id,
            'company_name'       => $employer->company_name,
            'email'              => $employer->email,
            'industry'           => $employer->industry,
            'contact'            => $employer->contact,
            'contact_person'     => $employer->contact_person,
            'first_name'         => $employer->first_name,
            'last_name'          => $employer->last_name,
            'city'               => $employer->city,
            'status'             => $employer->status,
            'verification_status'=> $employer->verification_status ?? 'pending',
            'total_hired'        => $employer->total_hired,
            'email_verified'     => !is_null($employer->email_verified_at),
        ];
    }
}
