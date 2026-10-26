<?php

declare(strict_types=1);

namespace Fixture;

final class Calc
{
    public static function add(int $a, int $b): int
    {
        return $a + $b;
    }
}
