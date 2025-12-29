<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use App\Services\TwoFactorService;

class TwoFactorController extends Controller
{
    protected $twoFactorService;

    public function __construct(TwoFactorService $twoFactorService)
    {
        $this->twoFactorService = $twoFactorService;
    }

    public function enableTotp(Request $request)
    {
        $user = $request->user();

        try {
            $data = $this->twoFactorService->enableTOTP($user);

            return response()->json([
                'success' => true,
                'message' => 'Scan the QR code with your authenticator app',
                'data' => $data
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to enable TOTP: ' . $e->getMessage()
            ], 500);
        }
    }

    public function confirmTotp(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'code' => 'required|string|size:6',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        $user = $request->user();

        if ($this->twoFactorService->verifyTOTP($user, $request->code)) {
            $this->twoFactorService->confirmTOTP($user);
            $recoveryCodes = $this->twoFactorService->getRecoveryCodes($user);

            return response()->json([
                'success' => true,
                'message' => 'TOTP 2FA enabled successfully',
                'recovery_codes' => $recoveryCodes
            ]);
        }

        return response()->json([
            'success' => false,
            'message' => 'Invalid verification code'
        ], 400);
    }

    public function enableSms(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'phone' => 'required|string|max:20',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        $user = $request->user();
        $user->update(['phone' => $request->phone]);

        if ($this->twoFactorService->sendSMSCode($user)) {
            return response()->json([
                'success' => true,
                'message' => 'Verification code sent to your phone'
            ]);
        }

        return response()->json([
            'success' => false,
            'message' => 'Failed to send SMS'
        ], 500);
    }

    public function confirmSms(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'code' => 'required|string|size:6',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        $user = $request->user();

        if ($this->twoFactorService->verifyCode($user, $request->code, 'sms')) {
            // Consume the code only when enabling 2FA
            $this->twoFactorService->consumeCode($user, $request->code, 'sms');
            $this->twoFactorService->enable2FA($user, 'sms');
            $recoveryCodes = $this->twoFactorService->getRecoveryCodes($user);

            return response()->json([
                'success' => true,
                'message' => 'SMS 2FA enabled successfully',
                'recovery_codes' => $recoveryCodes
            ]);
        }

        return response()->json([
            'success' => false,
            'message' => 'Invalid or expired verification code'
        ], 400);
    }

    public function enableEmail(Request $request)
    {
        $user = $request->user();

        if ($this->twoFactorService->sendEmailCode($user)) {
            return response()->json([
                'success' => true,
                'message' => 'Verification code sent to your email'
            ]);
        }

        return response()->json([
            'success' => false,
            'message' => 'Failed to send email'
        ], 500);
    }

    public function confirmEmail(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'code' => 'required|string|size:6',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        $user = $request->user();

        if ($this->twoFactorService->verifyCode($user, $request->code, 'email')) {
            // Consume the code only when enabling 2FA
            $this->twoFactorService->consumeCode($user, $request->code, 'email');
            $this->twoFactorService->enable2FA($user, 'email');
            $recoveryCodes = $this->twoFactorService->getRecoveryCodes($user);

            return response()->json([
                'success' => true,
                'message' => 'Email 2FA enabled successfully',
                'recovery_codes' => $recoveryCodes
            ]);
        }

        return response()->json([
            'success' => false,
            'message' => 'Invalid or expired verification code'
        ], 400);
    }

    public function verify2fa(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'user_id' => 'required|exists:users,id',
            'code' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        $user = User::find($request->user_id);
        $isValid = false;
        $verifiedMethod = null;

        switch ($user->two_factor_method) {
            case 'totp':
                $isValid = $this->twoFactorService->verifyTOTP($user, $request->code);
                if ($isValid) $verifiedMethod = 'TOTP (Google Authenticator)';
                break;
            case 'sms':
                $isValid = $this->twoFactorService->verifyCode($user, $request->code, 'sms');
                if ($isValid) {
                    $this->twoFactorService->consumeCode($user, $request->code, 'sms');
                    $verifiedMethod = 'SMS';
                }
                break;
            case 'email':
                $isValid = $this->twoFactorService->verifyCode($user, $request->code, 'email');
                if ($isValid) {
                    $this->twoFactorService->consumeCode($user, $request->code, 'email');
                    $verifiedMethod = 'Email';
                }
                break;
        }

        if (!$isValid) {
            $isValid = $this->twoFactorService->useRecoveryCode($user, $request->code);
            if ($isValid) $verifiedMethod = 'Recovery Code';
        }

        if ($isValid) {
            $token = $user->createToken('auth_token')->plainTextToken;

            return response()->json([
                'success' => true,
                'message' => "2FA verification successful via {$verifiedMethod}",
                'data' => [
                    'user' => $user,
                    'token' => $token,
                    'verified_method' => $verifiedMethod,
                ]
            ]);
        }

        return response()->json([
            'success' => false,
            'message' => 'Invalid verification code'
        ], 400);
    }

    public function sendCode(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'user_id' => 'required|exists:users,id',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        $user = User::find($request->user_id);

        $success = false;
        switch ($user->two_factor_method) {
            case 'sms':
                $success = $this->twoFactorService->sendSMSCode($user);
                break;
            case 'email':
                $success = $this->twoFactorService->sendEmailCode($user);
                break;
        }

        if ($success) {
            return response()->json([
                'success' => true,
                'message' => 'Verification code sent successfully'
            ]);
        }

        return response()->json([
            'success' => false,
            'message' => 'Failed to send verification code'
        ], 500);
    }

    public function disable(Request $request)
    {
        $user = $request->user();
        $this->twoFactorService->disable2FA($user);

        return response()->json([
            'success' => true,
            'message' => '2FA disabled successfully'
        ]);
    }

    public function getStatus(Request $request)
    {
        $user = $request->user();

        return response()->json([
            'success' => true,
            'data' => [
                'enabled' => $user->two_factor_enabled,
                'method' => $user->two_factor_method,
                'has_recovery_codes' => !empty($user->two_factor_recovery_codes),
            ]
        ]);
    }

    public function getRecoveryCodes(Request $request)
    {
        $user = $request->user();
        $codes = $this->twoFactorService->getRecoveryCodes($user);

        return response()->json([
            'success' => true,
            'data' => [
                'recovery_codes' => $codes
            ]
        ]);
    }
}