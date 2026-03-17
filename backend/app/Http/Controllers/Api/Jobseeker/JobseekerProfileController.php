<?php

namespace App\Http\Controllers\Api\Jobseeker;

use App\Http\Controllers\Controller;
use App\Models\JobseekerSkill;
use Illuminate\Http\Request;
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
            'contact' => 'sometimes|string|max:20',
            'address' => 'sometimes|string|max:255',
            'sex' => 'sometimes|in:male,female',
            'date_of_birth' => 'sometimes|date',
            'bio' => 'nullable|string',
            'latitude' => 'nullable|numeric',
            'longitude' => 'nullable|numeric',
            'skills' => 'nullable|array',
            'skills.*' => 'string|max:100',
        ]);

        DB::beginTransaction();
        try {
            $skills = $validated['skills'] ?? null;
            unset($validated['skills']);
            
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
                'resume_url' => \Illuminate\Support\Facades\Storage::disk('public')->url($path),
            ],
            'message' => 'Resume uploaded successfully',
        ]);
    }
}
