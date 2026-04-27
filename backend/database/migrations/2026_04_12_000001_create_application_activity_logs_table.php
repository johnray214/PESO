<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('application_activity_logs', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('application_id');
            $table->string('actor_type');   // 'employer' | 'peso'
            $table->string('actor_label');  // company name OR 'PESO'
            $table->string('action');       // e.g. 'Reviewing', 'Shortlisted', 'Invited'
            $table->timestamps();

            $table->foreign('application_id')
                  ->references('id')->on('applications')
                  ->onDelete('cascade');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('application_activity_logs');
    }
};
