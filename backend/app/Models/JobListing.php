<?php

namespace App\Models;

use App\Support\PublicStorageUrl;
use Illuminate\Database\Eloquent\Casts\Attribute;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class JobListing extends Model
{
    use HasFactory, SoftDeletes;

    /**
     * Always expose absolute storage URL for employer logo in JSON.
     * Relying on controller-only setAttribute() can omit non-column keys from
     * serialization in some cases; an accessor + $appends is reliable.
     *
     * @var list<string>
     */
    protected $appends = [
        'employer_photo_url',
        'is_peso_posted',
        'company_name',
        'employer_email',
        'employer_phone',
        'latitude',
        'longitude',
    ];

    protected $fillable = [
        'employer_id',
        'employer_name',
        'is_overseas',
        'title',
        'type',
        'location',
        'salary_range',
        'education_level',
        'experience_required',
        'description',
        'slots',
        'status',
        'posted_date',
        'deadline',
        'program',
        'program_budget',
        'program_duration',
        'program_target',
        'implementing_agency',
    ];

    protected $casts = [
        'posted_date'  => 'date',
        'deadline'     => 'date',
        'slots'        => 'integer',
        'is_overseas'  => 'boolean',
    ];

    public function employer()
    {
        return $this->belongsTo(Employer::class);
    }

    public function skills()
    {
        return $this->hasMany(JobSkill::class);
    }

    public function applications()
    {
        return $this->hasMany(Application::class);
    }

    public function isOpen(): bool
    {
        return $this->status === 'open';
    }

    public function scopeOpen($query)
    {
        return $query->where('status', 'open');
    }

    /**
     * Full public URL for the employer's logo (public disk under /storage/...).
     */
    protected function employerPhotoUrl(): Attribute
    {
        return Attribute::make(
            get: function (): ?string {
                if (! $this->relationLoaded('employer') || $this->employer === null) {
                    return null;
                }
                $stored = $this->employer->photo;
                if ($stored === null || $stored === '') {
                    return null;
                }

                return PublicStorageUrl::fromRequest(request(), $stored);
            }
        );
    }

    /**
     * Determine if job was posted directly by PESO Admin rather than an employer.
     */
    protected function isPesoPosted(): Attribute
    {
        return Attribute::make(
            get: fn(): bool => $this->employer_id === null
        );
    }

    /**
     * Fallback display company name: 'DOLE' for DOLE special programs,
     * 'PESO Santiago' for direct PESO posts, or employer company name.
     */
    protected function companyName(): Attribute
    {
        return Attribute::make(
            get: function (): string {
                if ($this->employer_id !== null && $this->relationLoaded('employer') && $this->employer !== null) {
                    return $this->employer->company_name ?? ($this->employer_name ?: 'PESO Santiago');
                }
                if (!empty($this->employer_name) && strtolower(trim($this->employer_name)) !== 'employer') {
                    return $this->employer_name;
                }
                $program = trim((string) $this->program);
                if ($program !== '' && strtolower($program) !== 'none') {
                    return 'Department of Labor and Employment';
                }
                return 'PESO Santiago';
            }
        );
    }

    /**
     * Contact email for the job listing:
     * - Returns the registered employer's email if posted by an employer.
     * - Falls back to the active PESO Admin account's email for DOLE/PESO posted jobs.
     */
    protected function employerEmail(): Attribute
    {
        return Attribute::make(
            get: function (): ?string {
                if ($this->employer_id !== null && $this->relationLoaded('employer') && $this->employer !== null) {
                    return $this->employer->email;
                }
                if ($this->employer_id !== null) {
                    $emp = Employer::find($this->employer_id);
                    if ($emp && !empty($emp->email)) {
                        return $emp->email;
                    }
                }
                // Fallback to PESO Admin account email configured in website
                static $adminEmail = null;
                if ($adminEmail === null) {
                    $adminEmail = User::where('role', 'admin')->where('status', 'active')->value('email')
                        ?? User::where('role', 'admin')->value('email')
                        ?? 'admin@peso.gov.ph';
                }
                return $adminEmail;
            }
        );
    }

    /**
     * Contact phone number for the job listing:
     * - Returns the registered employer's phone if posted by an employer.
     * - Falls back to the active PESO Admin account's contact number for DOLE/PESO posted jobs.
     */
    protected function employerPhone(): Attribute
    {
        return Attribute::make(
            get: function (): ?string {
                if ($this->employer_id !== null && $this->relationLoaded('employer') && $this->employer !== null) {
                    return $this->employer->phone;
                }
                if ($this->employer_id !== null) {
                    $emp = Employer::find($this->employer_id);
                    if ($emp && !empty($emp->phone)) {
                        return $emp->phone;
                    }
                }
                // Fallback to PESO Admin account contact number configured in website
                static $adminPhone = null;
                if ($adminPhone === null) {
                    $adminPhone = User::where('role', 'admin')->where('status', 'active')->value('contact')
                        ?? User::where('role', 'admin')->value('contact')
                        ?? '09001234567';
                }
                return $adminPhone;
            }
        );
    }

    /**
     * Fallback latitude:
     * - Returns employer's latitude if employer exists and has coordinates.
     * - If DOLE / PESO Santiago post, defaults to PESO Santiago Office latitude.
     */
    protected function latitude(): Attribute
    {
        return Attribute::make(
            get: function (): ?float {
                if ($this->employer_id !== null && $this->relationLoaded('employer') && $this->employer !== null && $this->employer->latitude !== null) {
                    return (float) $this->employer->latitude;
                }
                if ($this->employer_id !== null) {
                    $emp = Employer::find($this->employer_id);
                    if ($emp && $emp->latitude !== null) {
                        return (float) $emp->latitude;
                    }
                }
                if ($this->employer_id === null || $this->program !== null) {
                    return 16.68930015164032;
                }
                return null;
            }
        );
    }

    /**
     * Fallback longitude:
     * - Returns employer's longitude if employer exists and has coordinates.
     * - If DOLE / PESO Santiago post, defaults to PESO Santiago Office longitude.
     */
    protected function longitude(): Attribute
    {
        return Attribute::make(
            get: function (): ?float {
                if ($this->employer_id !== null && $this->relationLoaded('employer') && $this->employer !== null && $this->employer->longitude !== null) {
                    return (float) $this->employer->longitude;
                }
                if ($this->employer_id !== null) {
                    $emp = Employer::find($this->employer_id);
                    if ($emp && $emp->longitude !== null) {
                        return (float) $emp->longitude;
                    }
                }
                if ($this->employer_id === null || $this->program !== null) {
                    return 121.55596296008191;
                }
                return null;
            }
        );
    }
}

