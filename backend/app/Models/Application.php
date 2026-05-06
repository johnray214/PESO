<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Application extends Model
{
    use HasFactory;

    protected $fillable = [
        'job_listing_id',
        'jobseeker_id',
        'status',
        'offer_response',
        'offer_sent_at',
        'offer_response_at',
        'interview_date',
        'interview_time',
        'interview_format',
        'interview_location',
        'interviewer_name',
        'match_score',
        'applied_at',
    ];

    protected $casts = [
        'match_score' => 'integer',
        'applied_at' => 'datetime',
        'interview_date' => 'date',
        'offer_sent_at' => 'datetime',
        'offer_response_at' => 'datetime',
    ];

    public function jobListing()
    {
        return $this->belongsTo(JobListing::class);
    }

    public function jobseeker()
    {
        return $this->belongsTo(Jobseeker::class);
    }

    public static function calculateMatchScore(Jobseeker $jobseeker, JobListing $jobListing): int
    {
        $jobSkills = $jobListing->skills->pluck('skill')->map(fn($s) => strtolower($s))->toArray();
        
        if (empty($jobSkills)) {
            return 0;
        }

        $jobseekerSkills = $jobseeker->skills->pluck('skill')->map(fn($s) => strtolower($s))->toArray();
        
        $matchingSkills = array_intersect($jobseekerSkills, $jobSkills);
        
        return (int) round((count($matchingSkills) / count($jobSkills)) * 100);
    }
}
