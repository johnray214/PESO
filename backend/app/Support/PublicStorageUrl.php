<?php

namespace App\Support;

use Illuminate\Http\Request;
use Illuminate\Filesystem\FilesystemAdapter;
use Illuminate\Support\Facades\Storage;

final class PublicStorageUrl
{
    /**
     * URL for a public-disk path.
     * Uses Laravel's Storage::url() which picks up the correct URL from the default disk (e.g., S3/R2).
     */
    public static function fromRequest(Request $request, ?string $stored): ?string
    {
        if ($stored === null || $stored === '') {
            return null;
        }

        $stored = str_replace('\\', '/', trim($stored));

        if (preg_match('#^https?://#i', $stored)) {
            return $stored;
        }

        $stored = ltrim($stored, '/');

        // Mobile apps can be picky about some R2 domains/edge behavior.
        // For employer photos specifically, always go through our API proxy,
        // so the client fetches from the Railway domain.
        if (str_starts_with($stored, 'employers/photos/')) {
            return $request->getSchemeAndHttpHost() . '/api/public/storage/' . $stored;
        }

        // Prefer the configured "public" disk (local OR S3/R2).
        // Relying on Storage::url() ties URL generation to the *default* disk which can differ per env.
        try {
            /** @var FilesystemAdapter $disk */
            $disk = Storage::disk('public');

            // If the public disk is S3-compatible and objects are private, use a short-lived signed URL.
            // Set PUBLIC_DISK_SIGNED_URLS=true to enable.
            if (env('PUBLIC_DISK_SIGNED_URLS', false) && method_exists($disk, 'temporaryUrl')) {
                /** @var \DateTimeInterface $expiresAt */
                $expiresAt = now()->addMinutes((int) env('PUBLIC_DISK_SIGNED_URL_TTL_MINUTES', 15));
                return $disk->temporaryUrl($stored, $expiresAt);
            }

            $url = $disk->url($stored);
            if (is_string($url) && $url !== '') {
                // Local disk may return a relative URL (e.g. /storage/foo.jpg). Make it absolute for mobile.
                if (str_starts_with($url, '/')) {
                    return $request->getSchemeAndHttpHost() . $url;
                }
                return $url;
            }
        } catch (\Throwable $e) {
            // fall through to proxy/local fallback
        }

        // Last resort: serve via our API domain (works even when R2 bucket is private).
        return $request->getSchemeAndHttpHost() . '/api/public/storage/' . $stored;
    }
}
