<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Employer;
use App\Models\Jobseeker;
use App\Models\JobListing;
use App\Models\Event;
use Illuminate\Http\Request;

class AdminArchiveController extends Controller
{
    public function index(Request $request)
    {
        $type = $request->type;
        $results = [];

        switch ($type) {
            case 'users':
                $results = User::onlyTrashed()->orderByDesc('deleted_at')->paginate(15);
                break;
            case 'employers':
                $results = Employer::onlyTrashed()->orderByDesc('deleted_at')->paginate(15);
                break;
            case 'jobseekers':
                $results = Jobseeker::onlyTrashed()->orderByDesc('deleted_at')->paginate(15);
                break;
            case 'job_listings':
                $results = JobListing::onlyTrashed()->orderByDesc('deleted_at')->paginate(15);
                break;
            case 'events':
                $results = Event::onlyTrashed()->orderByDesc('deleted_at')->paginate(15);
                break;
            default:
                $results = [
                    'users' => User::onlyTrashed()->count(),
                    'employers' => Employer::onlyTrashed()->count(),
                    'jobseekers' => Jobseeker::onlyTrashed()->count(),
                    'job_listings' => JobListing::onlyTrashed()->count(),
                    'events' => Event::onlyTrashed()->count(),
                ];
                return response()->json([
                    'success' => true,
                    'data' => $results,
                ]);
        }

        return response()->json([
            'success' => true,
            'data' => $results,
        ]);
    }

    public function restore(Request $request, $type, $id)
    {
        $model = $this->getModel($type);
        
        if (!$model) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid type',
            ], 400);
        }

        $record = $model::onlyTrashed()->findOrFail($id);
        $record->restore();

        return response()->json([
            'success' => true,
            'message' => 'Record restored successfully',
        ]);
    }

    public function destroy(Request $request, $type, $id)
    {
        $model = $this->getModel($type);
        
        if (!$model) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid type',
            ], 400);
        }

        $record = $model::onlyTrashed()->findOrFail($id);
        $record->forceDelete();

        return response()->json([
            'success' => true,
            'message' => 'Record permanently deleted',
        ]);
    }

    private function getModel($type)
    {
        return match ($type) {
            'users' => User::class,
            'employers' => Employer::class,
            'jobseekers' => Jobseeker::class,
            'job_listings' => JobListing::class,
            'events' => Event::class,
            default => null,
        };
    }
}
