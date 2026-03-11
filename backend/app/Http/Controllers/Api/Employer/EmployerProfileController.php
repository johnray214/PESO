<?php

namespace App\Http\Controllers\Api\Employer;

use App\Http\Controllers\Controller;
use App\Models\AuditLog;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;

class EmployerProfileController extends Controller
{
    public function show(Request $request)
    {
        $employer = $request->user();

        return response()->json([
            'success' => true,
            'data'    => $this->formatProfile($employer),
        ]);
    }

    public function update(Request $request)
    {
        $employer = $request->user();

        $validator = Validator::make($request->all(), [
            'first_name'    => 'nullable|string|max:100',
            'last_name'     => 'nullable|string|max:100',
            'contact_role'  => 'nullable|string|max:100',
            'contact'       => 'nullable|string|max:20',
            'email'         => 'sometimes|required|email|unique:employers,email,' . $employer->id,
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $employer->update($request->only(['first_name', 'last_name', 'contact_role', 'contact', 'email']));

        AuditLog::record('Updated', 'Employers', "Profile updated for {$employer->company_name}", $request, $employer);

        return response()->json(['success' => true, 'message' => 'Profile updated', 'data' => $this->formatProfile($employer)]);
    }

    public function updateCompany(Request $request)
    {
        $employer = $request->user();

        $validator = Validator::make($request->all(), [
            'company_name'  => 'sometimes|required|string|max:255',
            'legal_name'    => 'nullable|string|max:255',
            'tagline'       => 'nullable|string|max:255',
            'about'         => 'nullable|string',
            'industry'      => 'nullable|string|max:100',
            'company_size'  => 'nullable|string|max:50',
            'founded'       => 'nullable|string|max:10',
            'business_type' => 'nullable|string|max:100',
            'tin'           => 'nullable|string|max:50',
            'city'          => 'nullable|string|max:100',
            'address'       => 'nullable|string|max:500',
            'website'       => 'nullable|url|max:255',
            'perks'         => 'nullable|array',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $employer->update($request->only([
            'company_name', 'legal_name', 'tagline', 'about', 'industry',
            'company_size', 'founded', 'business_type', 'tin', 'city', 'address', 'website', 'perks',
        ]));

        AuditLog::record('Updated', 'Employers', "Company info updated for {$employer->company_name}", $request, $employer);

        return response()->json(['success' => true, 'message' => 'Company info updated', 'data' => $this->formatProfile($employer)]);
    }

    public function changePassword(Request $request)
    {
        $employer = $request->user();

        $validator = Validator::make($request->all(), [
            'current_password' => 'required|string',
            'password'         => 'required|string|min:6|confirmed',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        if (!Hash::check($request->current_password, $employer->password)) {
            return response()->json(['message' => 'Current password is incorrect'], 422);
        }

        $employer->update(['password' => Hash::make($request->password)]);

        return response()->json(['success' => true, 'message' => 'Password changed successfully']);
    }

    private function formatProfile($employer): array
    {
        return [
            'id'            => $employer->id,
            'companyName'   => $employer->company_name,
            'legalName'     => $employer->legal_name,
            'tagline'       => $employer->tagline,
            'about'         => $employer->about,
            'industry'      => $employer->industry,
            'companySize'   => $employer->company_size,
            'founded'       => $employer->founded,
            'businessType'  => $employer->business_type,
            'tin'           => $employer->tin,
            'city'          => $employer->city,
            'address'       => $employer->address,
            'website'       => $employer->website,
            'perks'         => $employer->perks ?? [],
            'firstName'     => $employer->first_name,
            'lastName'      => $employer->last_name,
            'contactPerson' => $employer->contact_person,
            'contactRole'   => $employer->contact_role,
            'email'         => $employer->email,
            'phone'         => $employer->contact,
            'status'        => $employer->status,
            'verificationStatus' => $employer->verification_status ?? 'pending',
            'emailVerified' => !is_null($employer->email_verified_at),
            'totalHired'    => $employer->total_hired,
            'joinedDate'    => $employer->created_at->format('M d, Y'),
        ];
    }
}
