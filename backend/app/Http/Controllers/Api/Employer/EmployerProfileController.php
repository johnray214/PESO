<?php

namespace App\Http\Controllers\Api\Employer;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;

class EmployerProfileController extends Controller
{
    public function show(Request $request)
    {
        $employer = $request->user();
        
        return response()->json([
            'success' => true,
            'data' => $employer,
        ]);
    }

    public function update(Request $request)
    {
        $employer = $request->user();
        
        $validated = $request->validate([
            'company_name'   => 'sometimes|string|max:255',
            'contact_person' => 'sometimes|string|max:255',
            'email'          => 'sometimes|email|max:255',
            'industry'       => 'sometimes|string|max:100',
            'company_size'   => 'sometimes|string|max:30',
            'city'           => 'sometimes|string|max:100',
            'phone'          => 'sometimes|string|max:20',
            'tin'            => 'nullable|string|max:50',
            'website'        => 'nullable|string|max:255',
            'latitude'       => 'nullable|numeric',
            'longitude'      => 'nullable|numeric',
            'address_full'   => 'nullable|string|max:255',
            'map_visible'    => 'sometimes|boolean',
            // Extended profile fields stored as JSON or separate columns
            'tagline'        => 'nullable|string|max:500',
            'about'          => 'nullable|string',
            'legal_name'     => 'nullable|string|max:255',
            'business_type'  => 'nullable|string|max:100',
            'founded'        => 'nullable|string|max:10',
            'address'        => 'nullable|string|max:255',
            'perks'          => 'nullable|array',
        ]);

        $employer->update($validated);

        return response()->json([
            'success' => true,
            'data' => $employer,
            'message' => 'Profile updated successfully',
        ]);
    }

    public function changePassword(Request $request)
    {
        $request->validate([
            'current_password' => 'required|string',
            'password' => 'required|string|min:8|confirmed',
        ]);

        $employer = $request->user();

        if (!Hash::check($request->current_password, $employer->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Current password is incorrect',
            ], 422);
        }

        $employer->update(['password' => Hash::make($request->password)]);

        return response()->json([
            'success' => true,
            'message' => 'Password changed successfully',
        ]);
    }

    public function uploadDocuments(Request $request)
    {
        $employer = $request->user();
        
        $request->validate([
            'biz_permit' => 'nullable|file|mimes:pdf,jpg,jpeg,png|max:5120',
            'bir_cert' => 'nullable|file|mimes:pdf,jpg,jpeg,png|max:5120',
        ]);

        $paths = [];

        if ($request->hasFile('biz_permit')) {
            $path = $request->file('biz_permit')->store(
                "employer-docs/{$employer->id}",
                'public'
            );
            $employer->update(['biz_permit_path' => $path]);
            $paths['biz_permit'] = Storage::disk('public')->url($path);
        }

        if ($request->hasFile('bir_cert')) {
            $path = $request->file('bir_cert')->store(
                "employer-docs/{$employer->id}",
                'public'
            );
            $employer->update(['bir_cert_path' => $path]);
            $paths['bir_cert'] = Storage::disk('public')->url($path);
        }

        return response()->json([
            'success' => true,
            'data' => [
                'paths' => $paths,
            ],
            'message' => 'Documents uploaded successfully',
        ]);
    }
}
