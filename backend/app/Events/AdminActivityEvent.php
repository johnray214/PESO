<?php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class AdminActivityEvent implements ShouldBroadcastNow
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public array $payload;

    /**
     * @param string $type    Registration | Status | Event | System
     * @param string $title
     * @param string $message
     * @param string $id      Unique string id e.g. 'js_5', 'emp_3'
     */
    public function __construct(string $type, string $title, string $message, string $id)
    {
        $this->payload = [
            'id'      => $id,
            'type'    => $type,
            'title'   => $title,
            'message' => $message,
            'time'    => now()->toISOString(),
            'read'    => false,
        ];
    }

    /**
     * Broadcasts to the public admin-feed channel (no auth required for admin).
     */
    public function broadcastOn(): Channel
    {
        return new Channel('admin-feed');
    }

    public function broadcastAs(): string
    {
        return 'AdminActivityEvent';
    }

    public function broadcastWith(): array
    {
        return $this->payload;
    }
}
