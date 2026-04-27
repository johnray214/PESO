<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('legs_feedbacks', function (Blueprint $table) {
            $table->id();
            $table->string('first_name');
            $table->string('last_name');
            $table->string('middle_initial', 10)->nullable();
            $table->string('program');
            $table->string('venue')->nullable();
            $table->date('activity_date')->nullable();
            $table->unsignedTinyInteger('rating_program_content');   // 1–5
            $table->unsignedTinyInteger('rating_interaction');        // 1–5
            $table->unsignedTinyInteger('rating_mastery');            // 1–5
            $table->unsignedTinyInteger('rating_overall');            // 1–5
            $table->text('remarks')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('legs_feedbacks');
    }
};
