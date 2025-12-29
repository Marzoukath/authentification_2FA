<?php

namespace App\Services;

use App\Models\User;
use App\Models\VerificationCode;
use PragmaRX\Google2FA\Google2FA;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Mail;
use App\Mail\TwoFactorCodeMail;
use Twilio\Rest\Client as TwilioClient;

class TwoFactorService
{
    protected $google2fa;

    public function __construct()
    {
        $this->google2fa = new Google2FA();
    }

    public function enableTOTP(User $user): array
    {
        $secret = $this->google2fa->generateSecretKey();
        
        $user->update([
            'two_factor_secret' => encrypt($secret),
            'two_factor_method' => 'totp',
            'two_factor_enabled' => false,
        ]);

        $qrCodeUrl = $this->google2fa->getQRCodeUrl(
            config('app.name'),
            $user->email,
            $secret
        );

        return [
            'secret' => $secret,
            'qr_code_url' => $qrCodeUrl,
        ];
    }

    public function verifyTOTP(User $user, string $code): bool
    {
        $secret = decrypt($user->two_factor_secret);
        return $this->google2fa->verifyKey($secret, $code);
    }

    public function confirmTOTP(User $user): void
    {
        $user->update([
            'two_factor_enabled' => true,
            'two_factor_confirmed_at' => now(),
        ]);
        
        $this->generateRecoveryCodes($user);
    }

    public function sendSMSCode(User $user): bool
    {
        if (!$user->phone) {
            throw new \Exception('Phone number not provided');
        }

        // Clean up expired codes before generating new ones
        VerificationCode::cleanupExpiredCodes();

        $code = VerificationCode::generate($user->id, 'sms');

        // Check if we should use mock service (for development)
        if (config('services.sms.use_mock', true)) {
            return $this->sendMockSMS($user, $code);
        }

        // Use real SMS service
        try {
            $twilio = new TwilioClient(
                config('services.twilio.sid'),
                config('services.twilio.token')
            );

            $twilio->messages->create($user->phone, [
                'from' => config('services.twilio.phone'),
                'body' => "Your 2FA code is: {$code}. Valid for 10 minutes."
            ]);

            return true;
        } catch (\Exception $e) {
            \Log::error('SMS sending failed: ' . $e->getMessage());
            // Fallback to mock SMS for development
            return $this->sendMockSMS($user, $code);
        }
    }

    protected function sendMockSMS(User $user, string $code): bool
    {
        // Mock SMS sending for development
        \Log::info("MOCK SMS: Code {$code} sent to {$user->phone}");
        
        // In development, store the mock SMS in a special table or just log it
        if (app()->environment('local', 'development')) {
            // You could create a MockSMS table or just log it
            \Log::info("Mock SMS Code for {$user->phone}: {$code}");
        }
        
        return true;
    }

    public function sendEmailCode(User $user): bool
    {
        // Clean up expired codes before generating new ones
        VerificationCode::cleanupExpiredCodes();

        $code = VerificationCode::generate($user->id, 'email');

        try {
            Mail::to($user->email)->send(new TwoFactorCodeMail($code));
            return true;
        } catch (\Exception $e) {
            \Log::error('Email sending failed: ' . $e->getMessage());
            return false;
        }
    }

    public function verifyCode(User $user, string $code, string $type): bool
    {
        $verificationCode = VerificationCode::where('user_id', $user->id)
            ->where('code', $code)
            ->where('type', $type)
            ->where('used', false)
            ->latest()
            ->first();

        if (!$verificationCode || !$verificationCode->isValid()) {
            return false;
        }

        return true;
    }

    public function consumeCode(User $user, string $code, string $type): bool
    {
        $verificationCode = VerificationCode::where('user_id', $user->id)
            ->where('code', $code)
            ->where('type', $type)
            ->where('used', false)
            ->latest()
            ->first();

        if (!$verificationCode || !$verificationCode->isValid()) {
            return false;
        }

        $verificationCode->update(['used' => true]);
        return true;
    }

    public function enable2FA(User $user, string $method): void
    {
        $user->update([
            'two_factor_enabled' => true,
            'two_factor_method' => $method,
            'two_factor_confirmed_at' => now(),
        ]);

        $this->generateRecoveryCodes($user);
    }

    public function disable2FA(User $user): void
    {
        $user->update([
            'two_factor_enabled' => false,
            'two_factor_method' => 'none',
            'two_factor_secret' => null,
            'two_factor_recovery_codes' => null,
            'two_factor_confirmed_at' => null,
        ]);
    }

    protected function generateRecoveryCodes(User $user): array
    {
        $codes = [];
        for ($i = 0; $i < 8; $i++) {
            $codes[] = Str::random(10) . '-' . Str::random(10);
        }

        $user->setRecoveryCodesArray($codes);
        $user->save();

        return $codes;
    }

    public function getRecoveryCodes(User $user): array
    {
        return $user->getRecoveryCodesArray();
    }

    public function useRecoveryCode(User $user, string $code): bool
    {
        $codes = $user->getRecoveryCodesArray();
        
        if (in_array($code, $codes)) {
            $codes = array_diff($codes, [$code]);
            $user->setRecoveryCodesArray($codes);
            $user->save();
            return true;
        }

        return false;
    }
}