<?php

use App\Http\Controllers\AuthController;
use App\Http\Controllers\InterventionAttachmentController;
use App\Http\Controllers\InterventionController;
use Illuminate\Support\Facades\Route;

Route::name('api.')->group(function (): void {
    Route::post('/auth/login', [AuthController::class, 'login'])
        ->middleware('throttle:5,1')
        ->name('auth.login');

    Route::middleware('auth:sanctum')->group(function (): void {
        Route::get('/auth/me', [AuthController::class, 'me'])
            ->name('auth.me');
        Route::delete('/auth/logout', [AuthController::class, 'logout'])
            ->name('auth.logout');
        Route::apiResource('interventions', InterventionController::class)
            ->only(['index', 'store', 'show', 'update']);
        Route::post('/interventions/{intervention}/attachments', [InterventionAttachmentController::class, 'store'])
            ->name('interventions.attachments.store');
        Route::get('/interventions/{intervention}/attachments/{attachment}', [InterventionAttachmentController::class, 'show'])
            ->name('interventions.attachments.show');
    });
});
