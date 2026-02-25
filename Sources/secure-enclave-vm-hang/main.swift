import CryptoKit
import Foundation

print("SecureEnclave.isAvailable: \(SecureEnclave.isAvailable)")

guard SecureEnclave.isAvailable else {
    print("Secure Enclave is not available — nothing to demonstrate.")
    exit(0)
}

print("Attempting to create SecureEnclave.P256.KeyAgreement.PrivateKey()...")
print("If this hangs, it means the Secure Enclave is reported as available")
print("but key creation cannot complete (common on macOS VMs).")
print("")

// Use a DispatchWorkItem with a timeout so the process doesn't hang forever.
let done = DispatchSemaphore(value: 0)
var succeeded = false

let work = DispatchWorkItem {
    do {
        let key = try SecureEnclave.P256.KeyAgreement.PrivateKey()
        print("Key created successfully: \(key.publicKey.x963Representation.base64EncodedString())")
        succeeded = true
    } catch {
        print("Key creation threw an error: \(error)")
    }
    done.signal()
}

DispatchQueue.global().async(execute: work)

let timeout: DispatchTime = .now() + .seconds(10)
if done.wait(timeout: timeout) == .timedOut {
    print("")
    print("HANG DETECTED: SecureEnclave.P256.KeyAgreement.PrivateKey() did not")
    print("return within 10 seconds. This confirms the issue — SecureEnclave.isAvailable")
    print("returns true but key creation hangs indefinitely on this machine.")
    print("")
    print("This is a problem for macOS VMs (e.g. CI runners on Buildkite, GitHub Actions)")
    print("where the Sequoia exclave-based SEP proxy causes isAvailable to return true")
    print("but full CryptoKit key operations are not actually supported.")
    exit(1)
} else if succeeded {
    print("")
    print("No issue — key creation completed successfully on this machine.")
    exit(0)
} else {
    print("")
    print("Key creation failed with an error (see above).")
    exit(1)
}
