<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class Employer extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable, SoftDeletes;

    protected $fillable = [
        'company_name',
        'contact_person',
        'email',
        'password',
        'industry',
        'company_size',
        'city',
        'phone',
        'tin',
        'website',
        'biz_permit_path',
        'bir_cert_path',
        'latitude',
        'longitude',
        'address_full',
        'map_visible',
        'status',
        'verified_at',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected $casts = [
        'password' => 'hashed',
        'latitude' => 'decimal:8',
        'longitude' => 'decimal:8',
        'map_visible' => 'boolean',
        'verified_at' => 'datetime',
    ];

    public function jobListings()
    {
        return $this->hasMany(JobListing::class);
    }

    public function notificationReads()
    {
        return $this->morphMany(NotificationRead::class, 'recipient');
    }

    public function isApproved(): bool
    {
        return $this->status === 'approved';
    }

    public function openJobsCount(): int
    {
        return $this->jobListings()->where('status', 'open')->count();
    }
}
