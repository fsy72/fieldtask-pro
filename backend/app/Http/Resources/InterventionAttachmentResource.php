<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class InterventionAttachmentResource extends JsonResource
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
            'type' => $this->type,
            'caption' => $this->caption,
            'mime_type' => $this->mime_type,
            'size_bytes' => $this->size_bytes,
            'download_url' => route('api.v1.interventions.attachments.show', [
                'intervention' => $this->intervention_id,
                'attachment' => $this->id,
            ]),
        ];
    }
}
