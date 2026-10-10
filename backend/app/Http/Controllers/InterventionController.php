<?php

namespace App\Http\Controllers;

use App\Http\Requests\StoreInterventionRequest;
use App\Http\Requests\UpdateInterventionRequest;
use App\Http\Resources\InterventionResource;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class InterventionController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        $filters = $request->validate([
            'status' => ['sometimes', 'in:pending,in_progress,completed'],
            'search' => ['sometimes', 'string', 'max:255'],
            'priority' => ['sometimes', 'in:asc,desc'],
            'per_page' => ['sometimes', 'integer', 'between:1,100'],
        ]);

        $interventions = $request->user()
            ->interventions()
            ->with('attachments')
            ->when(isset($filters['status']), function (Builder $query) use ($filters): void {
                $query->where('status', $filters['status']);
            })
            ->when(isset($filters['search']), function (Builder $query) use ($filters): void {
                $search = '%'.$filters['search'].'%';

                $query->where(function (Builder $query) use ($search): void {
                    $query->where('client', 'like', $search)
                        ->orWhere('address', 'like', $search)
                        ->orWhere('description', 'like', $search)
                        ->orWhere('equipment', 'like', $search);
                });
            })
            ->when(($filters['priority'] ?? 'desc') === 'asc', function (Builder $query): void {
                $query->orderBy('priority');
            }, function (Builder $query): void {
                $query->orderByDesc('priority');
            })
            ->orderBy('scheduled_at')
            ->orderBy('id')
            ->paginate($filters['per_page'] ?? 20)
            ->withQueryString();

        return InterventionResource::collection($interventions);
    }

    public function store(StoreInterventionRequest $request): JsonResponse
    {
        $attributes = $request->validated();
        $clientUuid = $attributes['client_uuid'] ?? null;
        unset($attributes['client_uuid']);

        if ($clientUuid !== null) {
            $intervention = $request->user()->interventions()->firstOrCreate(
                ['client_uuid' => $clientUuid],
                $attributes,
            );
        } else {
            $intervention = $request->user()->interventions()->create($attributes);
        }

        return (new InterventionResource($intervention))
            ->response()
            ->setStatusCode($intervention->wasRecentlyCreated ? 201 : 200);
    }

    public function show(Request $request, string $intervention): InterventionResource
    {
        return new InterventionResource(
            $request->user()->interventions()->with('attachments')->findOrFail($intervention),
        );
    }

    public function update(
        UpdateInterventionRequest $request,
        string $intervention,
    ): JsonResponse|InterventionResource {
        $model = $request->user()->interventions()->findOrFail($intervention);
        $attributes = $request->validated();
        $expectedVersion = (int) $attributes['sync_version'];
        unset($attributes['sync_version']);

        if ($model->sync_version !== $expectedVersion) {
            return response()->json([
                'message' => 'Cette intervention a été modifiée depuis votre dernière synchronisation.',
                'current' => new InterventionResource($model->load('attachments')),
            ], 409);
        }

        $attributes['sync_version'] = $expectedVersion + 1;
        $updated = $request->user()
            ->interventions()
            ->whereKey($model->getKey())
            ->where('sync_version', $expectedVersion)
            ->update($attributes);

        if ($updated === 0) {
            $current = $request->user()
                ->interventions()
                ->with('attachments')
                ->findOrFail($intervention);

            return response()->json([
                'message' => 'Cette intervention a été modifiée depuis votre dernière synchronisation.',
                'current' => new InterventionResource($current),
            ], 409);
        }

        return new InterventionResource($model->refresh()->load('attachments'));
    }
}
