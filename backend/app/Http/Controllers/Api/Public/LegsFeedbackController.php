<?php

namespace App\Http\Controllers\Api\Public;

use App\Http\Controllers\Controller;
use App\Models\LegsFeedback;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class LegsFeedbackController extends Controller
{
    /**
     * POST /api/legs-feedback
     * Store a new LEGS feedback submission (public – no auth required).
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'first_name'             => 'required|string|max:100',
            'last_name'              => 'required|string|max:100',
            'middle_initial'         => 'nullable|string|max:10',
            'program'                => 'required|string|max:100',
            'venue'                  => 'nullable|string|max:200',
            'activity_date'          => 'nullable|date',
            'rating_program_content' => 'required|integer|min:1|max:5',
            'rating_interaction'     => 'required|integer|min:1|max:5',
            'rating_mastery'         => 'required|integer|min:1|max:5',
            'rating_overall'         => 'required|integer|min:1|max:5',
            'remarks'                => 'nullable|string|max:2000',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Validation failed.',
                'errors'  => $validator->errors(),
            ], 422);
        }

        $feedback = LegsFeedback::create($validator->validated());

        return response()->json([
            'message'  => 'Feedback submitted successfully.',
            'feedback' => $feedback,
        ], 201);
    }

    /**
     * GET /api/admin/legs-feedback
     * List all submissions (admin-protected in the route file).
     */
    public function index(Request $request)
    {
        $query = LegsFeedback::query()->latest();

        if ($request->filled('program')) {
            $query->where('program', $request->program);
        }

        if ($request->filled('search')) {
            $q = $request->search;
            $query->where(function ($q2) use ($q) {
                $q2->where('first_name', 'like', "%{$q}%")
                   ->orWhere('last_name',  'like', "%{$q}%")
                   ->orWhere('venue',      'like', "%{$q}%");
            });
        }

        return response()->json($query->paginate(20));
    }
}
