import CryptoKit
import Foundation

print("SecureEnclave.isAvailable: \(SecureEnclave.isAvailable)")

guard SecureEnclave.isAvailable else {
    print("Secure Enclave is not available — nothing to demonstrate.")
    exit(0)
}

print("Attempting to create SecureEnclave.P256.KeyAgreement.PrivateKey()...")
print("On macOS VMs this may crash (SIGTRAP) or hang indefinitely because")
print("SecureEnclave.isAvailable returns true but there is no real Secure")
print("Enclave hardware to service the request.")
print("")

// Run the key creation in a subprocess so we can detect both crashes and hangs.
let executableURL = URL(fileURLWithPath: ProcessInfo.processInfo.arguments[0])

if CommandLine.arguments.contains("--create-key") {
    // Child process: attempt key creation directly.
    do {
        let key = try SecureEnclave.P256.KeyAgreement.PrivateKey()
        print("KEY_CREATED: \(key.publicKey.x963Representation.base64EncodedString())")
    } catch {
        print("KEY_ERROR: \(error)")
        exit(1)
    }
    exit(0)
}

// Parent process: spawn child with a timeout.
let process = Process()
process.executableURL = executableURL
process.arguments = ["--create-key"]

let pipe = Pipe()
process.standardOutput = pipe
process.standardError = pipe

do {
    try process.run()
} catch {
    print("Failed to spawn subprocess: \(error)")
    exit(1)
}

// Wait up to 10 seconds for the child to finish.
let deadline = Date().addingTimeInterval(10)
while process.isRunning && Date() < deadline {
    Thread.sleep(forTimeInterval: 0.1)
}

if process.isRunning {
    process.terminate()
    print("HANG DETECTED: SecureEnclave.P256.KeyAgreement.PrivateKey() did not")
    print("return within 10 seconds. SecureEnclave.isAvailable returns true but")
    print("key creation hangs indefinitely on this machine.")
    exit(1)
}

let outputData = pipe.fileHandleForReading.readDataToEndOfFile()
let output = String(data: outputData, encoding: .utf8) ?? ""

if process.terminationStatus == 0 && output.contains("KEY_CREATED") {
    print("No issue — key creation completed successfully on this machine.")
    print(output)
    exit(0)
} else if process.terminationReason == .uncaughtSignal || process.terminationStatus != 0 {
    print("CRASH DETECTED: The subprocess terminated abnormally.")
    print("  Exit status: \(process.terminationStatus)")
    print("  Termination reason: \(process.terminationReason == .uncaughtSignal ? "uncaught signal" : "exit")")
    if !output.isEmpty {
        print("  Output: \(output.trimmingCharacters(in: .whitespacesAndNewlines))")
    }
    print("")
    print("SecureEnclave.isAvailable returns true but key creation crashes on this")
    print("machine. This is typical of macOS VMs without real Secure Enclave hardware.")
    exit(1)
} else {
    print("Unexpected result:")
    print(output)
    exit(1)
}
