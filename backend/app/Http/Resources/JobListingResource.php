<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class JobListingResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $hasEmployer = $this->employer_id !== null && $this->relationLoaded('employer') && $this->employer !== null;
        $isDole = !empty($this->program) && strtolower(trim((string)$this->program)) !== 'none';
        
        $companyName = $hasEmployer 
            ? ($this->employer->company_name ?? $this->employer_name ?? 'PESO Santiago')
            : ($isDole ? 'Department of Labor and Employment' : ($this->employer_name ?: 'PESO Santiago'));

        return [
            'id' => $this->id,
            'employer_id' => $this->employer_id,
            'employer_name' => $this->employer_name,
            'company' => $companyName,
            'is_peso_posted' => $this->employer_id === null,
            'program' => $this->program,
            'program_budget' => $this->program_budget,
            'program_duration' => $this->program_duration,
            'program_target' => $this->program_target,
            'implementing_agency' => $this->implementing_agency,
            'employer' => $this->whenLoaded('employer', fn() => [
                'id' => $this->employer->id,
                'company_name' => $this->employer->company_name,
                'photo' => $this->employer->photo,
            ]),
            'title' => $this->title,
            'type' => $this->type,
            'location' => $this->location,
            'salary_range' => $this->salary_range,
            'education_level' => $this->education_level,
            'experience_required' => $this->experience_required,
            'description' => $this->description,
            'slots' => $this->slots,
            'status' => $this->status,
            'posted_date' => $this->posted_date,
            'deadline' => $this->deadline,
            'is_overseas' => (bool) $this->is_overseas,
            'skills' => $this->whenLoaded('skills', fn() => $this->skills->pluck('skill')),
            'applications_count' => $this->whenCounted('applications'),
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}
