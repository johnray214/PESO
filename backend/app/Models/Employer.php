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

    protected $fillable = [
        'company_name',
        'email',
        'password',
        'industry',
        'contact',
        'contact_person',
        'email_verified_at',
        'status',
        'total_hired',
    ];

    protected $hidden = [
        'password',
    ];

    protected $casts = [
        'email_verified_at' => 'datetime',
        'total_hired' => 'integer',
    ];

    public function jobListings()
    {
        return $this->hasMany(JobListing::class);
    }
}
