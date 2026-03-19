<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Facades\Storage;

class EmployerResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'             => $this->id,
            'company_name'   => $this->company_name,
            'contact_person' => $this->contact_person,
            'email'          => $this->email,
            'industry'       => $this->industry,
            'company_size'   => $this->company_size,

            // ── Address ──────────────────────────────────────────────
            'barangay'       => $this->barangay,
            'city'           => $this->city,
            'province'       => $this->province,
            'address_full'   => $this->address_full,
            'latitude'       => $this->latitude,
            'longitude'      => $this->longitude,
            'map_visible'    => $this->map_visible,

            // ── Contact ───────────────────────────────────────────────
            'phone'          => $this->phone,
            'tin'            => $this->tin,
            'website'        => $this->website,

            // ── Extended Profile ──────────────────────────────────────
            'tagline'        => $this->tagline,
            'about'          => $this->about,
            'legal_name'     => $this->company_name,
            'business_type'  => $this->business_type,
            'founded'        => $this->founded,
            'perks'          => $this->perks ?? [],

            // ── Status ────────────────────────────────────────────────
            'status'         => $this->status,
            'verified_at'    => $this->verified_at,

            // ── Documents ─────────────────────────────────────────────
            'biz_permit_url' => $this->biz_permit_path
                ? Storage::disk('public')->url($this->biz_permit_path)
                : null,
            'bir_cert_url'   => $this->bir_cert_path
                ? Storage::disk('public')->url($this->bir_cert_path)
                : null,

            // ── Stats ─────────────────────────────────────────────────
            'stats' => [
                'active_listings'  => $this->whenLoaded('jobs', fn() =>
                    $this->jobs->where('status', 'open')->count(), 0),
                'total_applicants' => $this->whenLoaded('jobs', fn() =>
                    $this->jobs->sum('applications_count'), 0),
                'total_hired'      => $this->total_hired ?? 0,
                'member_since'     => $this->created_at?->year,
            ],

            // ── Jobs Preview ──────────────────────────────────────────
            'jobs' => $this->whenLoaded('jobs', fn() =>
                $this->jobs->map(fn($j) => [
                    'title'      => $j->title,
                    'type'       => $j->employment_type,
                    'location'   => $j->location,
                    'salary'     => $j->salary_range,
                    'status'     => ucfirst($j->status),
                    'applicants' => $j->applications_count ?? 0,
                ])
            ),

            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}