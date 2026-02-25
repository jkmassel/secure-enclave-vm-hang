# SecureEnclave VM Hang Demo

Demonstrates an issue where `SecureEnclave.isAvailable` returns `true` on macOS
virtual machines (e.g. CI runners) but `SecureEnclave.P256.KeyAgreement.PrivateKey()`
crashes or hangs because there is no real Secure Enclave hardware to service
the request.

## Background

On Apple Silicon Macs running macOS Sequoia, VMs gain limited Secure Enclave
proxy support (for Apple ID, iCloud, and FileVault) via "exclaves." This appears
to cause `SecureEnclave.isAvailable` to return `true` inside the VM guest, even
though full CryptoKit key generation operations are not supported.

Depending on the VM configuration, key creation may:
- **Crash** with a `SIGTRAP` (system trap)
- **Hang** indefinitely, never returning

This is a problem for any Swift code that checks `SecureEnclave.isAvailable`
before attempting to create keys — the check passes but the operation fails.

## Running

```
git clone https://github.com/jkmassel/secure-enclave-vm-hang.git
cd secure-enclave-vm-hang
swift run
```

On a physical Mac with Secure Enclave hardware, you'll see:

```
SecureEnclave.isAvailable: true
No issue — key creation completed successfully on this machine.
```

On a macOS VM (Buildkite, GitHub Actions, Tart, etc.), you'll see one of:

```
CRASH DETECTED: The subprocess terminated abnormally.
```

```
HANG DETECTED: SecureEnclave.P256.KeyAgreement.PrivateKey() did not
return within 10 seconds.
```

## Workaround

Skip Secure Enclave operations in CI by checking for the `CI` environment
variable, or use `#if targetEnvironment(simulator)` when building for
simulators (which don't have this issue since `isAvailable` returns `false`).
