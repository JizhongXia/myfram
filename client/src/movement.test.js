import { describe, it, expect } from 'vitest';

function velocityFromKeys({ left, right, speed }) {
  let vx = 0;
  if (left) vx -= speed;
  if (right) vx += speed;
  return vx;
}

describe('movement helpers', () => {
  it('combines left/right', () => {
    expect(velocityFromKeys({ left: true, right: false, speed: 220 })).toBe(-220);
    expect(velocityFromKeys({ left: false, right: true, speed: 220 })).toBe(220);
    expect(velocityFromKeys({ left: false, right: false, speed: 220 })).toBe(0);
  });
});
