<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('job_listings', function (Blueprint $table) {
            $table->id();
            $table->string('title');
            $table->string('company');
            $table->string('company_initial', 5);
            // Hex color without '#', e.g. '3B82F6' — Flutter parses as Color(0xFF3B82F6)
            $table->string('company_color', 10)->default('3B82F6');
            $table->string('location');
            $table->text('description');
            $table->json('requirements')->nullable();
            $table->json('skills')->nullable();
            $table->string('experience_level');
            $table->string('salary_min', 30);
            $table->string('salary_max', 30);
            $table->string('employment_type', 30)->default('Full-time');
            $table->unsignedTinyInteger('match_percentage')->default(0);
            $table->boolean('is_urgent')->default(false);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('job_listings');
    }
};
