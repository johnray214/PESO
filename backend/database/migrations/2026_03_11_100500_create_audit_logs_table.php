<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('audit_logs', function (Blueprint $table) {
            $table->id();
            $table->string('user_type')->nullable(); // App\Models\PesoEmployee, App\Models\Employer, App\Models\User
            $table->unsignedBigInteger('user_id')->nullable();
            $table->string('user_name')->nullable();
            $table->string('role')->nullable(); // Admin, Staff, Employer
            $table->string('action'); // Created, Updated, Deleted, Logged In, Status Changed, Exported
            $table->string('module'); // Applicants, Employers, Events, Job Listings, Users, System
            $table->text('detail')->nullable();
            $table->string('ip_address', 45)->nullable();
            $table->timestamps();

            $table->index(['user_type', 'user_id']);
            $table->index('action');
            $table->index('module');
            $table->index('created_at');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('audit_logs');
    }
};
