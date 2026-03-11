<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\AuditLog;
use App\Models\Employer;
use App\Models\Event;
use App\Models\JobListing;
use App\Models\User;
use Illuminate\Http\Request;

class AdminArchiveController extends Controller
{
    private array $typeMap = [
        'applicant'   => User::class,
        'event'       => Event::class,
        'job_listing' => JobListing::class,
        'employer'    => Employer::class,
    ];

    public function index(Request $request)
    {
        $type   = $request->get('type', 'all');
        $search = $request->get('search');
        $records = collect();

        $types = $type === 'all' ? array_keys($this->typeMap) : [$type];

        foreach ($types as $t) {
            $model = $this->typeMap[$t] ?? null;
            if (!$model) continue;

            $query = $model::onlyTrashed();

            if ($search) {
                $nameCol = $t === 'applicant' ? 'name' : ($t === 'employer' ? 'company_name' : 'title');
                $query->where($nameCol, 'like', "%{$search}%");
            }

            $query->get()->each(function ($item) use (&$records, $t) {
                $name = match ($t) {
                    'applicant'   => $item->name,
                    'employer'    => $item->company_name,
                    default       => $item->title,
                };
                $detail = match ($t) {
                    'applicant'   => $item->email,
                    'employer'    => $item->industry ?? 'N/A',
                    'event'       => $item->location,
                    'job_listing' => $item->company,
                    default       => '',
                };
                $records->push([
                    'id'        => $item->id,
                    'type'      => ucfirst(str_replace('_', ' ', $t)),
                    'name'      => $name,
                    'detail'    => $detail,
                    'deletedAt' => $item->deleted_at->format('M d, Y H:i'),
                ]);
            });
        }

        $sorted = $records->sortByDesc('deletedAt')->values();

        return response()->json(['success' => true, 'data' => $sorted]);
    }

    public function restore(Request $request, string $type, $id)
    {
        $model = $this->typeMap[$type] ?? null;
        if (!$model) {
            return response()->json(['message' => 'Invalid type'], 422);
        }

        $item = $model::onlyTrashed()->findOrFail($id);
        $item->restore();

        AuditLog::record('Updated', ucfirst($type) . 's', "Record #{$id} restored from archive", $request, $request->user());

        return response()->json(['success' => true, 'message' => 'Record restored']);
    }

    public function forceDelete(Request $request, string $type, $id)
    {
        $model = $this->typeMap[$type] ?? null;
        if (!$model) {
            return response()->json(['message' => 'Invalid type'], 422);
        }

        $item = $model::onlyTrashed()->findOrFail($id);
        $item->forceDelete();

        AuditLog::record('Deleted', ucfirst($type) . 's', "Record #{$id} permanently deleted", $request, $request->user());

        return response()->json(['success' => true, 'message' => 'Record permanently deleted']);
    }

    public function clearAll(Request $request, string $type = 'all')
    {
        $types = $type === 'all' ? array_keys($this->typeMap) : [$type];

        foreach ($types as $t) {
            $model = $this->typeMap[$t] ?? null;
            if ($model) {
                $model::onlyTrashed()->forceDelete();
            }
        }

        AuditLog::record('Deleted', 'Archive', "All archived records cleared (type: {$type})", $request, $request->user());

        return response()->json(['success' => true, 'message' => 'Archive cleared']);
    }
}
