<?php

declare(strict_types=1);

use Fixture\Calc;
use PHPUnit\Framework\TestCase;

final class CalcTest extends TestCase
{
    public function testAdd(): void
    {
        $this->assertSame(5, Calc::add(2, 3));
    }

    // The self-test sets FIXTURE_FAIL=1 to prove that a failing test turns the pipeline red.
    public function testFailsOnRequest(): void
    {
        $this->assertNotSame('1', getenv('FIXTURE_FAIL'));
    }
}
