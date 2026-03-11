<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->enum('peso_status', ['processing', 'placed', 'hired', 'rejected'])->nullable()->after('skills');
            $table->text('education')->nullable()->after('peso_status');
            $table->text('experience')->nullable()->after('education');
            $table->text('notes')->nullable()->after('experience');
            $table->softDeletes();
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['peso_status', 'education', 'experience', 'notes', 'deleted_at']);
        });
    }
};
