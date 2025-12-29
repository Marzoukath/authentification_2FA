<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Carbon\Carbon;

class VerificationCode extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'code',
        'type',
        'used',
        'expires_at',
    ];

    protected $casts = [
        'used' => 'boolean',
        'expires_at' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function isExpired(): bool
    {
        return Carbon::now()->isAfter($this->expires_at);
    }

    public function isValid(): bool
    {
        return !$this->used && !$this->isExpired();
    }

    public static function generate(int $userId, string $type): string
    {
        $code = str_pad(random_int(0, 999999), 6, '0', STR_PAD_LEFT);
        
        self::create([
            'user_id' => $userId,
            'code' => $code,
            'type' => $type,
            'expires_at' => Carbon::now()->addMinutes(10),
        ]);

        return $code;
    }

    public static function cleanupExpiredCodes(): int
    {
        return self::where('expires_at', '<', Carbon::now())->delete();
    }

    public static function cleanupOldCodes(): int
    {
        // Clean up codes older than 24 hours to prevent database bloat
        return self::where('created_at', '<', Carbon::now()->subDay())->delete();
    }
}
