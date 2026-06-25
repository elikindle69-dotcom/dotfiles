pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string configDir: Quickshell.env("HOME") + "/.config/quickshell"
    readonly property string scriptPath: configDir + "/Services/Crypto/vault_crypto.py"
    readonly property string metaPath: configDir + "/Assets/passwords/vault.meta"
    readonly property string vaultPath: configDir + "/Assets/passwords/vault.enc"
    property string tmpDir: ""

    property bool isUnlocked: false
    property bool isFirstRun: false
    property string encryptionKey: ""
    property string vaultSalt: ""
    property string masterHash: ""
    property string masterSalt: ""

    signal unlockSucceeded()
    signal unlockFailed(string reason)
    signal passwordSet()
    signal vaultLoaded(string plaintext)
    signal vaultSaved()
    signal operationFailed(string error)

    property string _pendingPassword: ""

    Component.onCompleted: {
        _initConfig()
        _loadMeta()
    }

    function _initConfig() {
        const rand = Math.floor(Math.random() * 999999)
        tmpDir = "/tmp/qs-pm-" + rand
        mkdirProc.exec({ command: ["mkdir", "-p", configDir + "/Assets/passwords"] })
        mkdirTmpProc.exec({ command: ["mkdir", "-p", tmpDir] })
        chmodProc.exec({ command: ["chmod", "700", configDir + "/Assets/passwords"] })
    }

    Process { id: mkdirProc }
    Process { id: mkdirTmpProc }
    Process { id: chmodProc }
    Process { id: chmodMetaProc }
    Process { id: chmodVaultProc }
    Process { id: rmTmpProc }

    FileView {
        id: metaFile
        path: root.metaPath
        watchChanges: false
        blockLoading: true

        onLoaded: {
            try {
                const data = JSON.parse(metaFile.text())
                root.masterSalt = data.kdf.salt
                root.masterHash = data.verifier
                root.isFirstRun = false
            } catch (e) {
                root.isFirstRun = true
            }
        }

        onFileChanged: reload()
    }

    function _loadMeta() {
        metaFile.reload()
    }

    function _writeTmpAndRun(filename, jsonData, proc) {
        const path = tmpDir + "/" + filename
        tmpWriteProc.targetPath = path
        tmpWriteProc.jsonData = jsonData
        tmpWriteProc.targetProc = proc
        tmpWriteProc.targetArg = path
        tmpWriteProc.running = true
        tmpWriteProc.write(jsonData)
        tmpWriteProc.stdinEnabled = false
    }

    Process {
        id: tmpWriteProc
        stdinEnabled: true
        command: ["tee"]
        property string targetPath: ""
        property string jsonData: ""
        property var targetProc: null
        property string targetArg: ""

        onExited: (exitCode) => {
            if (exitCode === 0 && targetProc) {
                targetProc.command = ["python3", root.scriptPath, targetProc._subcommand, targetArg]
                targetProc.running = true
            }
        }
    }

    function _runCrypto(subcommand, jsonData, stdoutHandler) {
        const path = tmpDir + "/" + subcommand + ".json"
        const writeProc = _findOrMakeWriter(path, jsonData)
        const cryptoProc = _findOrMakeRunner(subcommand, path, stdoutHandler)
        writeProc.running = true
        writeProc.write(jsonData)
        writeProc.stdinEnabled = false
    }

    // --- Hash ---
    Process {
        id: hashWriteProc
        stdinEnabled: true
        command: ["tee", root.tmpDir + "/hash_input.json"]

        onExited: (exitCode) => {
            if (exitCode === 0) {
                hashRunProc.running = true
            }
        }
    }

    Process {
        id: hashRunProc
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const result = JSON.parse(this.text)
                    root.masterSalt = result.salt
                    root.masterHash = result.verifier

                    const meta = JSON.stringify({
                        version: 1,
                        algorithm: "argon2id+xchacha20poly1305",
                        kdf: {
                            algorithm: "argon2id",
                            iterations: 3,
                            memory_cost: 65536,
                            lanes: 4,
                            salt: result.salt
                        },
                        verifier: result.verifier
                    }, null, 2)

                    writeMetaProc.running = true
                    writeMetaProc.write(meta)
                    writeMetaProc.stdinEnabled = false
                } catch (e) {
                    root.operationFailed("hash failed: " + e)
                }
            }
        }

        onExited: (exitCode) => {
            if (exitCode !== 0) {
                root.operationFailed("hash_password failed with code " + exitCode)
            }
        }
    }

    Process {
        id: writeMetaProc
        stdinEnabled: true
        command: ["tee", root.metaPath]

        onExited: (exitCode) => {
            if (exitCode === 0) {
                chmodMetaProc.exec({ command: ["chmod", "600", root.metaPath] })
                root.isFirstRun = false
                root.passwordSet()
            }
        }
    }

    function setMasterPassword(password) {
        if (password.length < 12) {
            root.operationFailed("password must be at least 12 characters")
            return
        }
        const input = JSON.stringify({ password: password })
        hashWriteProc.running = true
        hashWriteProc.write(input)
        hashWriteProc.stdinEnabled = false
        hashRunProc.command = ["python3", root.scriptPath, "hash_password", root.tmpDir + "/hash_input.json"]
    }

    // --- Verify ---
    Process {
        id: verifyWriteProc
        stdinEnabled: true
        command: ["tee", root.tmpDir + "/verify_input.json"]

        onExited: (exitCode) => {
            root._log("verifyWriteProc exited code=" + exitCode)
            if (exitCode === 0) {
                root._log("starting verifyRunProc")
                verifyRunProc.running = true
            }
        }
    }

    Process {
        id: verifyRunProc
        stdout: StdioCollector {
            onStreamFinished: {
                root._log("verifyRunProc stdout: " + this.text)
                try {
                    const result = JSON.parse(this.text)
                    if (result.valid) {
                        root._log("verify OK, calling _doUnlock")
                        root._doUnlock(root._pendingPassword)
                    } else {
                        root._log("verify FAILED: invalid password")
                        root.unlockFailed("invalid password")
                    }
                } catch (e) {
                    root._log("verify parse error: " + e)
                    root.unlockFailed("verification error: " + e)
                }
                root._pendingPassword = ""
            }
        }

        stderr: StdioCollector {
            onStreamFinished: { root._log("verify stderr: " + this.text) }
        }

        onExited: (exitCode) => {
            root._log("verifyRunProc exited code=" + exitCode)
            if (exitCode !== 0) {
                root._log("verifyRunProc failed, clearing pending password")
                root.unlockFailed("invalid password")
                root._pendingPassword = ""
            }
        }
    }

    property bool debug: true

    function _log(msg) { if (debug) console.log("[PM:debug] " + msg) }

    function unlock(password) {
        _log("unlock() called, password length=" + password.length)
        _log("masterSalt=" + root.masterSalt)
        _log("masterHash=" + root.masterHash)
        _log("metaPath=" + root.metaPath)
        _log("vaultPath=" + root.vaultPath)
        _log("tmpDir=" + root.tmpDir)
        _log("scriptPath=" + root.scriptPath)
        _pendingPassword = password
        const input = JSON.stringify({
            password: password,
            salt: root.masterSalt,
            verifier: root.masterHash
        })
        _log("verify input: " + input)
        verifyWriteProc.running = true
        verifyWriteProc.write(input)
        verifyWriteProc.stdinEnabled = false
        verifyRunProc.command = ["python3", root.scriptPath, "verify_password", root.tmpDir + "/verify_input.json"]
        _log("verify command: " + JSON.stringify(verifyRunProc.command))
    }

    // --- Derive Key ---
    Process {
        id: deriveWriteProc
        stdinEnabled: true
        command: ["tee", root.tmpDir + "/derive_input.json"]

        onExited: (exitCode) => {
            root._log("deriveWriteProc exited code=" + exitCode)
            if (exitCode === 0) {
                root._log("starting deriveRunProc")
                deriveRunProc.running = true
            }
        }
    }

    Process {
        id: deriveRunProc
        stdout: StdioCollector {
            onStreamFinished: {
                root._log("deriveRunProc stdout: " + this.text)
                try {
                    const result = JSON.parse(this.text)
                    root.encryptionKey = result.key
                    root._log("key derived, calling _doDecrypt")
                    root._doDecrypt()
                } catch (e) {
                    root._log("derive error: " + e)
                    root.unlockFailed("key derivation failed: " + e)
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: { root._log("derive stderr: " + this.text) }
        }
    }

    function _doUnlock(password) {
        root._log("_doUnlock() setting vaultSalt=" + root.masterSalt)
        root.vaultSalt = root.masterSalt
        const input = JSON.stringify({
            password: password,
            salt: root.masterSalt
        })
        root._log("derive input: " + input)
        deriveWriteProc.running = true
        deriveWriteProc.write(input)
        deriveWriteProc.stdinEnabled = false
        deriveRunProc.command = ["python3", root.scriptPath, "derive_key", root.tmpDir + "/derive_input.json"]
        root._log("derive command: " + JSON.stringify(deriveRunProc.command))
    }

    // --- Decrypt Vault ---
    Process {
        id: decryptWriteProc
        stdinEnabled: true
        command: ["tee", root.tmpDir + "/decrypt_input.json"]

        onExited: (exitCode) => {
            root._log("decryptWriteProc exited code=" + exitCode)
            if (exitCode === 0) {
                root._log("starting decryptRunProc")
                decryptRunProc.running = true
            }
        }
    }

    Process {
        id: decryptRunProc
        stdout: StdioCollector {
            onStreamFinished: {
                root._log("decryptRunProc stdout: " + this.text)
                try {
                    const result = JSON.parse(this.text)
                    if (result.error) {
                        root._log("decrypt ERROR: " + result.error)
                        root.unlockFailed(result.error)
                        return
                    }
                    var plaintext = result.plaintext
                    try { JSON.parse(plaintext); root._log("plaintext is valid JSON") } catch (e) {
                        root._log("plaintext is NOT JSON, trying atob. raw=" + plaintext.substring(0, 60))
                        plaintext = root.atob(plaintext)
                        root._log("after atob: " + plaintext.substring(0, 120))
                    }
                    root.isUnlocked = true
                    root._log("vaultLoaded emitting, plaintext length=" + plaintext.length)
                    root.vaultLoaded(plaintext)
                    root._log("unlockSucceeded emitting")
                    root.unlockSucceeded()
                } catch (e) {
                    root._log("decrypt exception: " + e)
                    root.unlockFailed("decryption failed: " + e)
                }
            }
        }
    }

    Process {
        id: readVaultProc
        command: ["cat", root.vaultPath]

        stdout: StdioCollector {
            onStreamFinished: {
                const raw = this.text.trim()
                root._log("readVaultProc stdout length=" + raw.length + " first100=" + raw.substring(0, 100))
                if (!raw) {
                    root._log("vault file empty, loading empty vault")
                    root.isUnlocked = true
                    root.vaultLoaded('{"version":1,"entries":[],"categories":[],"settings":{"autoLockTimeout":300000,"clipboardClearTimeout":30000}}')
                    root.unlockSucceeded()
                    return
                }

                try {
                    const decoded = root.atob(raw)
                    root._log("atob decoded: " + decoded.substring(0, 120))
                    const parts = JSON.parse(decoded)
                    root._log("parts nonce=" + parts.nonce + " ct=" + parts.ciphertext.substring(0, 30))
                    const input = JSON.stringify({
                        key: root.encryptionKey,
                        salt: root.vaultSalt,
                        nonce: parts.nonce,
                        ciphertext: parts.ciphertext
                    })
                    root._log("decrypt input salt=" + root.vaultSalt + " key=" + (root.encryptionKey ? root.encryptionKey.substring(0, 10) + "..." : "EMPTY"))
                    decryptWriteProc.running = true
                    decryptWriteProc.write(input)
                    decryptWriteProc.stdinEnabled = false
                    decryptRunProc.command = ["python3", root.scriptPath, "decrypt_vault", root.tmpDir + "/decrypt_input.json"]
                    root._log("decrypt command: " + JSON.stringify(decryptRunProc.command))
                } catch (e) {
                    root._log("vault parse error: " + e)
                    root.unlockFailed("vault file corrupted: " + e)
                }
            }
        }

        onExited: (exitCode) => {
            root._log("readVaultProc exited code=" + exitCode)
            if (exitCode !== 0) {
                root._log("readVaultProc failed, loading empty vault")
                root.isUnlocked = true
                root.vaultLoaded('{"version":1,"entries":[],"categories":[],"settings":{"autoLockTimeout":300000,"clipboardClearTimeout":30000}}')
                root.unlockSucceeded()
            }
        }
    }

    function _doDecrypt() {
        root._log("_doDecrypt() called, vaultPath=" + root.vaultPath)
        readVaultProc.running = true
    }

    // --- Encrypt + Save ---
    Process {
        id: encryptWriteProc
        stdinEnabled: true
        command: ["tee", root.tmpDir + "/encrypt_input.json"]

        onExited: (exitCode) => {
            if (exitCode === 0) {
                encryptRunProc.running = true
            }
        }
    }

    Process {
        id: encryptRunProc
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const result = JSON.parse(this.text)
                    writeVaultProc.running = true
                    writeVaultProc.write(result.blob)
                    writeVaultProc.stdinEnabled = false
                } catch (e) {
                    root.operationFailed("encryption failed: " + e)
                }
            }
        }
    }

    Process {
        id: writeVaultProc
        stdinEnabled: true
        command: ["tee", root.vaultPath]

        onExited: (exitCode) => {
            if (exitCode === 0) {
                chmodVaultProc.exec({ command: ["chmod", "600", root.vaultPath] })
                root.vaultSaved()
            }
        }
    }

    function saveVault(plaintext) {
        if (!root.isUnlocked || !root.encryptionKey) {
            root.operationFailed("vault is locked")
            return
        }

        if (!root.vaultSalt) {
            root.vaultSalt = root.masterSalt
        }

        const input = JSON.stringify({
            key: root.encryptionKey,
            salt: root.vaultSalt,
            plaintext: plaintext
        })

        encryptWriteProc.running = true
        encryptWriteProc.write(input)
        encryptWriteProc.stdinEnabled = false
        encryptRunProc.command = ["python3", root.scriptPath, "encrypt_vault", root.tmpDir + "/encrypt_input.json"]
    }

    // --- Generate Password ---
    Process {
        id: genWriteProc
        stdinEnabled: true
        command: ["tee", root.tmpDir + "/gen_input.json"]

        onExited: (exitCode) => {
            if (exitCode === 0) {
                genRunProc.running = true
            }
        }
    }

    Process {
        id: genRunProc
        property var callback: null

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const result = JSON.parse(this.text)
                    if (genRunProc.callback) genRunProc.callback(result.password)
                } catch (e) {
                    root.operationFailed("password generation failed")
                }
            }
        }
    }

    function generatePassword(length, callback) {
        genRunProc.callback = callback
        const input = JSON.stringify({ length: length || 20, charset: "alphanumeric" })
        genWriteProc.running = true
        genWriteProc.write(input)
        genWriteProc.stdinEnabled = false
        genRunProc.command = ["python3", root.scriptPath, "generate_password", root.tmpDir + "/gen_input.json"]
    }

    // --- Lock ---
    function lock() {
        isUnlocked = false
        encryptionKey = ""
        vaultSalt = ""
        rmTmpProc.exec({ command: ["rm", "-rf", tmpDir] })
    }

    // --- Helpers ---
    function atob(str) {
        var b64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
        var ret = ""
        var i = 0
        for (i = 0; i < str.length; i += 4) {
            var c1 = b64.indexOf(str[i])
            var c2 = b64.indexOf(str[i + 1])
            var c3 = b64.indexOf(str[i + 2])
            var c4 = b64.indexOf(str[i + 3])
            var b1 = (c1 << 2) | (c2 >> 4)
            var b2 = ((c2 & 15) << 4) | (c3 >> 2)
            var b3 = ((c3 & 3) << 6) | c4
            ret += String.fromCharCode(b1)
            if (c3 !== 64) ret += String.fromCharCode(b2)
            if (c4 !== 64) ret += String.fromCharCode(b3)
        }
        return ret
    }
}
