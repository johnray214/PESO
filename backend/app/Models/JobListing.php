<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class JobListing extends Model
{
    protected $fillable = [
        'title',
        'company',
        'company_initial',
        'company_color',
        'location',
        'latitude',
        'longitude',
        'description',
        'requirements',
        'skills',
        'experience_level',
        'salary_min',
        'salary_max',
        'employment_type',
        'category',
        'match_percentage',
        'is_urgent',
        'is_active',
    ];

    protected $casts = [
        'requirements'     => 'array',
        'skills'           => 'array',
        'is_urgent'        => 'boolean',
        'is_active'        => 'boolean',
        'match_percentage' => 'integer',
        'latitude'         => 'float',
        'longitude'        => 'float',
    ];

    public function applications()
    {
        return $this->hasMany(JobApplication::class);
    }

    public function savedJobs()
    {
        return $this->hasMany(SavedJob::class);
    }
}
