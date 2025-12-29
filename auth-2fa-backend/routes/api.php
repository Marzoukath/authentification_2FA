<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\TwoFactorController;

// Routes publiques
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

// Routes pour la vérification 2FA (pas besoin d'être authentifié)
Route::post('/2fa/verify', [TwoFactorController::class, 'verify2fa']);
Route::post('/2fa/send-code', [TwoFactorController::class, 'sendCode']);

// Routes protégées (nécessitent un token)
Route::middleware('auth:sanctum')->group(function () {
    // Auth routes
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/user', [AuthController::class, 'user']);

    // 2FA Management routes
    Route::prefix('2fa')->group(function () {
        // TOTP (QR Code)
        Route::post('/totp/enable', [TwoFactorController::class, 'enableTotp']);
        Route::post('/totp/confirm', [TwoFactorController::class, 'confirmTotp']);

        // SMS
        Route::post('/sms/enable', [TwoFactorController::class, 'enableSms']);
        Route::post('/sms/confirm', [TwoFactorController::class, 'confirmSms']);

        // Email
        Route::post('/email/enable', [TwoFactorController::class, 'enableEmail']);
        Route::post('/email/confirm', [TwoFactorController::class, 'confirmEmail']);

        // General
        Route::post('/disable', [TwoFactorController::class, 'disable']);
        Route::get('/status', [TwoFactorController::class, 'getStatus']);
        Route::get('/recovery-codes', [TwoFactorController::class, 'getRecoveryCodes']);
    });
});