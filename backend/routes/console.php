<?php

use App\Console\Commands\CloseExpiredJobs;
use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

// Auto-close job listings that have passed their deadline — runs daily at 00:01
Schedule::command('jobs:close-expired')->dailyAt('00:01');
