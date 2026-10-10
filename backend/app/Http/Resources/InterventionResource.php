<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class InterventionResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'client_uuid' => $this->client_uuid,
            'client' => $this->client,
            'address' => $this->address,
            'description' => $this->description,
            'equipment' => $this->equipment,
            'status' => $this->status,
            'priority' => $this->priority,
            'latitude' => $this->latitude,
            'longitude' => $this->longitude,
            'scheduled_at' => $this->scheduled_at?->toISOString(),
            'notes' => $this->notes,
            'sync_version' => $this->sync_version,
            'attachments' => InterventionAttachmentResource::collection(
                $this->whenLoaded('attachments'),
            ),
            'updated_at' => $this->updated_at?->toISOString(),
        ];
    }
}
