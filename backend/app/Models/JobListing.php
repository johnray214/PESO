<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class JobListing extends Model
{
    use \Illuminate\Database\Eloquent\SoftDeletes;

    protected $fillable = [
        'employer_id', 'title', 'company', 'company_initial', 'company_color',
        'location', 'latitude', 'longitude', 'description', 'requirements', 'skills',
        'experience_level', 'salary_min', 'salary_max', 'employment_type', 'category',
        'match_percentage', 'is_urgent', 'is_active',
        'slots', 'hired_count', 'status', 'closes_at',
    ];

    protected $casts = [
        'requirements'     => 'array',
        'skills'           => 'array',
        'is_urgent'        => 'boolean',
        'is_active'        => 'boolean',
        'match_percentage' => 'integer',
        'latitude'         => 'float',
        'longitude'        => 'float',
        'slots'            => 'integer',
        'hired_count'      => 'integer',
        'closes_at'        => 'date',
    ];

    public function employer()
    {
        return $this->belongsTo(Employer::class);
    }

    public function applications()
    {
        return $this->hasMany(JobApplication::class);
    }

    public function savedJobs()
    {
        return $this->hasMany(SavedJob::class);
    }
}
