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
            'id' => $this->id,
            'company_name' => $this->company_name,
            'contact_person' => $this->contact_person,
            'email' => $this->email,
            'industry' => $this->industry,
            'company_size' => $this->company_size,
            'city' => $this->city,
            'phone' => $this->phone,
            'tin' => $this->tin,
            'website' => $this->website,
            'latitude' => $this->latitude,
            'longitude' => $this->longitude,
            'address_full' => $this->address_full,
            'map_visible' => $this->map_visible,
            'status' => $this->status,
            'verified_at' => $this->verified_at,
            'biz_permit_url' => $this->biz_permit_path ? Storage::disk('public')->url($this->biz_permit_path) : null,
            'bir_cert_url' => $this->bir_cert_path ? Storage::disk('public')->url($this->bir_cert_path) : null,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}
