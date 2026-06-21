const test = require('node:test');
const assert = require('node:assert');
const { hashPassword, verifyPassword } = require('../src/utils/password');

test('hashPassword produces a verifiable, non-plaintext hash', () => {
  const hash = hashPassword('Secret@123');
  assert.notStrictEqual(hash, 'Secret@123');
  assert.strictEqual(verifyPassword('Secret@123', hash), true);
  assert.strictEqual(verifyPassword('WrongPassword', hash), false);
});
