<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        // MySQL requires an ALTER COLUMN to change an ENUM definition.
        // We add jobposting & feedback, and keep skillmatch for backward-compat
        // (existing rows won't break). New code no longer writes skillmatch.
        DB::statement("ALTER TABLE `reports` MODIFY `type` ENUM(
            'placement',
            'registration',
            'skills',
            'events',
            'employer',
            'skillmatch',
            'jobposting',
            'feedback'
        ) NOT NULL");
    }

    public function down(): void
    {
        DB::statement("ALTER TABLE `reports` MODIFY `type` ENUM(
            'placement',
            'registration',
            'skills',
            'events',
            'employer',
            'skillmatch'
        ) NOT NULL");
    }
};
