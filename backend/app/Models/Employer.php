<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class Employer extends Authenticatable
{
    use HasFactory, Notifiable, HasApiTokens;

    use \Illuminate\Database\Eloquent\SoftDeletes;

    protected $fillable = [
        'company_name', 'email', 'password', 'industry', 'contact', 'contact_person',
        'first_name', 'last_name', 'contact_role', 'legal_name', 'tagline', 'about',
        'company_size', 'founded', 'business_type', 'tin', 'city', 'address', 'website',
        'perks', 'verification_status', 'biz_permit_url', 'bir_cert_url', 'remarks',
        'email_verified_at', 'status', 'total_hired',
    ];

    protected $hidden = [
        'password',
    ];

    protected $casts = [
        'email_verified_at' => 'datetime',
        'total_hired' => 'integer',
        'perks' => 'array',
    ];

    public function jobListings()
    {
        return $this->hasMany(JobListing::class);
    }
}
