<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\AdminNotificationState;
use App\Models\NotificationRead;

class PruneNotifications extends Command
{
    protected $signature = 'notifications:prune';
    protected $description = 'Automatically delete notification records older than 30 days';

    public function handle()
    {
        $cutoff = now()->subDays(30);

        $adminCount = AdminNotificationState::where('created_at', '<', $cutoff)->delete();
        $readCount  = NotificationRead::where('created_at', '<', $cutoff)->whereNotNull('read_at')->delete();

        $this->info("Pruned {$adminCount} admin states and {$readCount} recipient notification records older than 30 days.");
        return Command::SUCCESS;
    }
}
