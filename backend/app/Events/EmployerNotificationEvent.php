<?php

namespace App\Events;

use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class EmployerNotificationEvent implements ShouldBroadcastNow
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public array $payload;
    public int $employerId;

    /**
     * @param int    $employerId  The employer's ID (for private channel routing)
     * @param int    $notifReadId The NotificationRead row ID (frontend uses this as the notification id)
     * @param string $type        applicant | match | job | system
     * @param string $title
     * @param string $message
     */
    public function __construct(int $employerId, int $notifReadId, string $type, string $title, string $message)
    {
        $this->employerId = $employerId;
        $this->payload = [
            'id'      => $notifReadId,
            'type'    => $type,
            'title'   => $title,
            'message' => $message,
            'time'    => now()->toISOString(),
            'read'    => false,
        ];
    }

    /**
     * Private channel so only the authenticated employer receives it.
     * Channel name: private-employer.{id}
     */
    public function broadcastOn(): PrivateChannel
    {
        return new PrivateChannel("employer.{$this->employerId}");
    }

    public function broadcastAs(): string
    {
        return 'EmployerNotificationEvent';
    }

    public function broadcastWith(): array
    {
        return $this->payload;
    }
}
