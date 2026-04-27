<?php

namespace App\Http\Controllers\Api\Public;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Filesystem\FilesystemAdapter;
use Illuminate\Support\Facades\Storage;

class PublicStorageController extends Controller
{
    /**
     * Stream a public asset stored on the "public" disk.
     *
     * This exists to support S3/R2 deployments where direct bucket access is
     * private or not publicly routable from the mobile app.
     */
    public function show(Request $request, string $path)
    {
        $path = str_replace('\\', '/', $path);
        $path = ltrim($path, '/');

        // Prevent path traversal.
        if ($path === '' || str_contains($path, '..')) {
            abort(404);
        }

        // Allow-list what can be publicly fetched.
        // Employer company photo uploads are stored here.
        $allowedPrefixes = [
            'employers/photos/',
        ];

        $isAllowed = false;
        foreach ($allowedPrefixes as $prefix) {
            if (str_starts_with($path, $prefix)) {
                $isAllowed = true;
                break;
            }
        }

        if (! $isAllowed) {
            abort(404);
        }

        if (! Storage::disk('public')->exists($path)) {
            abort(404);
        }

        /** @var FilesystemAdapter $disk */
        $disk = Storage::disk('public');

        return $disk->response($path, basename($path), [
            'Cache-Control' => 'public, max-age=86400',
        ]);
    }
}

