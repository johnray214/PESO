<?php

namespace App\Console\Commands;

use App\Models\JobListing;
use Illuminate\Console\Command;

class CloseExpiredJobs extends Command
{
    protected $signature   = 'jobs:close-expired';
    protected $description = 'Auto-close job listings whose deadline has passed';

    public function handle(): int
    {
        $count = JobListing::whereRaw('LOWER(status) = ?', ['open'])
            ->whereNotNull('deadline')
            ->where('deadline', '<', now()->toDateString())
            ->update(['status' => 'closed']);

        $this->info("Closed {$count} expired job listing(s).");

        return Command::SUCCESS;
    }
}
