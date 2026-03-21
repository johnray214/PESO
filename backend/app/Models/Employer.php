<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class Employer extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable, SoftDeletes;

    protected $fillable = [
        // ── Account ───────────────────────────────────────────────────
        'company_name',
        'legal_name',
        'contact_person',
        'email',
        'password',

        // ── Company Info ──────────────────────────────────────────────
        'industry',
        'company_size',
        'tagline',
        'about',
        'business_type',
        'founded',
        'perks',

        // ── Address ───────────────────────────────────────────────────
        'barangay',
        'city',
        'province',
        'address_full',
        'latitude',
        'longitude',
        'map_visible',

        // ── Contact ───────────────────────────────────────────────────
        'phone',
        'tin',
        'website',

        // ── Documents ─────────────────────────────────────────────────
        'biz_permit_path',
        'bir_cert_path',

        // ── Stats ─────────────────────────────────────────────────────
        'total_hired',

        // ── Status ────────────────────────────────────────────────────
        'status',
        'verified_at',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    // Single $casts — merged from your original + new fields needed by the resource
    protected $casts = [
        'password'    => 'hashed',
        'latitude'    => 'decimal:8',
        'longitude'   => 'decimal:8',
        'map_visible' => 'boolean',
        'verified_at' => 'datetime',
        // perks is JSON in DB → always an array in PHP
        'perks'       => 'array',
        'founded'     => 'integer',
        'total_hired' => 'integer',
    ];

    // ── Relationships ─────────────────────────────────────────────────────────

    public function jobListings()
    {
        return $this->hasMany(JobListing::class);
    }

    // Alias so EmployerResource whenLoaded('jobs') works without renaming everywhere
    public function jobs()
    {
        return $this->hasMany(JobListing::class);
    }

    public function notificationReads()
    {
        return $this->morphMany(NotificationRead::class, 'recipient');
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    public function isApproved(): bool
    {
        return $this->status === 'approved';
    }

    public function openJobsCount(): int
    {
        return $this->jobListings()->where('status', 'open')->count();
    }
}