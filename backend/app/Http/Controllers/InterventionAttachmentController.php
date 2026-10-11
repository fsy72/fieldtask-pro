<?php

namespace App\Http\Controllers;

use App\Http\Requests\StoreInterventionAttachmentRequest;
use App\Http\Resources\InterventionAttachmentResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\HttpFoundation\StreamedResponse;

class InterventionAttachmentController extends Controller
{
    public function store(
        StoreInterventionAttachmentRequest $request,
        string $intervention,
    ): JsonResponse {
        $model = $request->user()->interventions()->findOrFail($intervention);
        $clientUuid = $request->validated('client_uuid');
        if ($clientUuid !== null) {
            $existing = $model->attachments()
                ->where('client_uuid', $clientUuid)
                ->first();
            if ($existing !== null) {
                return (new InterventionAttachmentResource($existing))
                    ->response()
                    ->setStatusCode(200);
            }
        }

        $file = $request->file('file');
        $path = $file->store('interventions/'.$model->getKey(), 'local');

        $attachment = $model->attachments()->create([
            'client_uuid' => $clientUuid,
            'type' => $request->validated('type'),
            'path' => $path,
            'caption' => $request->validated('caption'),
            'mime_type' => $file->getMimeType() ?? 'application/octet-stream',
            'size_bytes' => $file->getSize(),
        ]);

        return (new InterventionAttachmentResource($attachment))
            ->response()
            ->setStatusCode(201);
    }

    public function show(
        Request $request,
        string $intervention,
        string $attachment,
    ): StreamedResponse {
        $model = $request->user()->interventions()->findOrFail($intervention);
        $file = $model->attachments()->findOrFail($attachment);

        abort_unless(Storage::disk('local')->exists($file->path), 404);

        return Storage::disk('local')->download(
            $file->path,
            basename($file->path),
            ['Content-Type' => $file->mime_type],
        );
    }
}
