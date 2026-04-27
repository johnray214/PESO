<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('job_listings', function (Blueprint $table) {
            $table->string('program')->nullable();
            $table->string('program_budget')->nullable();
            $table->string('program_duration')->nullable();
            $table->string('program_target')->nullable();
            $table->string('implementing_agency')->nullable();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('job_listings', function (Blueprint $table) {
            $table->dropColumn([
                'program',
                'program_budget',
                'program_duration',
                'program_target',
                'implementing_agency'
            ]);
        });
    }
};
