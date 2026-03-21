<?php

namespace App\Http\Controllers\Api\Jobseeker;

use App\Http\Controllers\Controller;
use App\Models\JobseekerSkill;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\DB;

class JobseekerProfileController extends Controller
{
    public function show(Request $request)
    {
        $jobseeker = $request->user()->load('skills');
        
        return response()->json([
            'success' => true,
            'data' => $jobseeker,
        ]);
    }

    public function update(Request $request)
    {
        $jobseeker = $request->user();
        
        $validated = $request->validate([
            'first_name' => 'sometimes|string|max:100',
            'last_name' => 'sometimes|string|max:100',
            'contact' => 'sometimes|nullable|string|max:20',
            'address' => 'sometimes|nullable|string|max:500',
            'email' => 'sometimes|email|unique:jobseekers,email,' . $jobseeker->id,
            'sex' => 'sometimes|in:male,female',
            'date_of_birth' => 'sometimes|date',
            'bio' => 'nullable|string',
            'province_code' => 'sometimes|nullable|string|max:20',
            'province_name' => 'sometimes|nullable|string|max:120',
            'city_code' => 'sometimes|nullable|string|max:20',
            'city_name' => 'sometimes|nullable|string|max:120',
            'barangay_code' => 'sometimes|nullable|string|max:20',
            'barangay_name' => 'sometimes|nullable|string|max:120',
            'street_address' => 'sometimes|nullable|string|max:255',
            'latitude' => 'nullable|numeric',
            'longitude' => 'nullable|numeric',
            'skills' => 'nullable|array',
            'skills.*' => 'string|max:100',
        ]);

        DB::beginTransaction();
        try {
            $skills = $validated['skills'] ?? null;
            unset($validated['skills']);

            if (!array_key_exists('address', $validated)) {
                $parts = [
                    $validated['street_address'] ?? $jobseeker->street_address,
                    $validated['barangay_name'] ?? $jobseeker->barangay_name,
                    $validated['city_name'] ?? $jobseeker->city_name,
                    $validated['province_name'] ?? $jobseeker->province_name,
                ];
                $parts = array_values(array_filter(array_map(
                    fn ($p) => is_string($p) ? trim($p) : '',
                    $parts
                )));
                if (!empty($parts)) {
                    $validated['address'] = implode(', ', $parts);
                }
            }
            
            $jobseeker->update($validated);
            
            if ($skills !== null) {
                $jobseeker->skills()->delete();
                foreach ($skills as $skill) {
                    JobseekerSkill::create([
                        'jobseeker_id' => $jobseeker->id,
                        'skill' => $skill,
                    ]);
                }
            }
            
            DB::commit();

            return response()->json([
                'success' => true,
                'data' => $jobseeker->load('skills'),
                'message' => 'Profile updated successfully',
            ]);
        } catch (\Exception $e) {
            DB::rollback();
            throw $e;
        }
    }

    public function changePassword(Request $request)
    {
        $request->validate([
            'current_password' => 'required|string',
            'password' => 'required|string|min:8|confirmed',
        ]);

        $jobseeker = $request->user();

        if (!\Illuminate\Support\Facades\Hash::check($request->current_password, $jobseeker->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Current password is incorrect',
            ], 422);
        }

        $jobseeker->update(['password' => \Illuminate\Support\Facades\Hash::make($request->password)]);

        return response()->json([
            'success' => true,
            'message' => 'Password changed successfully',
        ]);
    }

    public function uploadResume(Request $request)
    {
        $request->validate([
            'resume' => 'required|file|mimes:pdf,doc,docx|max:5120',
        ]);

        $jobseeker = $request->user();

        $path = $request->file('resume')->store(
            "resumes/{$jobseeker->id}",
            'public'
        );
        
        $jobseeker->update(['resume_path' => $path]);

        return response()->json([
            'success' => true,
            'data' => [
                'resume_path' => $path,
            ],
            'message' => 'Resume uploaded successfully',
        ]);
    }

    public function uploadAvatar(Request $request)
    {
        $request->validate([
            'avatar' => 'required|image|max:3072', // 3MB
        ]);

        $jobseeker = $request->user();

        $path = $request->file('avatar')->store(
            "avatars/jobseekers/{$jobseeker->id}",
            'public'
        );

        $jobseeker->update(['avatar_path' => $path]);

        return response()->json([
            'success' => true,
            'data' => [
                'avatar_path' => $path,
            ],
            'message' => 'Avatar uploaded successfully',
        ]);
    }

    public function avatar(Request $request)
    {
        $jobseeker = $request->user();
        $path = $jobseeker->avatar_path;

        if (!$path) {
            return response()->noContent();
        }

        if (!Storage::disk('public')->exists($path)) {
            return response()->noContent();
        }

        return response()->file(Storage::disk('public')->path($path));
    }
}
