pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    property var entries: ({})
    property var categoryList: ["all", "dev", "social", "finance", "email", "other"]
    property string searchQuery: ""
    property string selectedCategory: "all"
    property var displayEntries: []

    signal vaultChanged()
    signal entryAdded(string id)
    signal entryUpdated(string id)
    signal entryDeleted(string id)

    Connections {
        target: CryptoService
        function onVaultLoaded(plaintext) { root.loadFromJSON(plaintext) }
    }

    function loadFromJSON(jsonStr) {
        try {
            const data = JSON.parse(jsonStr)
            entries = {}
            const list = data.entries || []
            for (let i = 0; i < list.length; i++) {
                const entry = list[i]
                entries[entry.id] = entry
            }
            const savedCategories = data.categories || []
            const merged = {}
            for (let i = 0; i < savedCategories.length; i++) merged[savedCategories[i]] = true
            for (const id in entries) {
                if (entries[id].category) merged[entries[id].category] = true
            }
            const result = []
            result.push("all")
            for (const cat in merged) result.push(cat)
            categoryList = result
            _refreshDisplay()
        } catch (e) {
            console.error("[VaultService] parse error:", e)
        }
    }

    function toJSON() {
        const list = []
        for (const id in entries) {
            list.push(entries[id])
        }
        return JSON.stringify({
            version: 1,
            entries: list,
            categories: categoryList.filter(function(c) { return c !== "all" }),
            settings: {
                autoLockTimeout: 300000,
                clipboardClearTimeout: 30000
            }
        })
    }

    function addEntry(name, username, password, url, notes, category) {
        const id = _generateId()
        const now = Date.now()
        entries[id] = {
            id: id,
            name: name,
            username: username || "",
            password: password || "",
            url: url || "",
            notes: notes || "",
            category: category || "other",
            created: now,
            modified: now
        }
        _ensureCategory(category || "other")
        _refreshDisplay()
        entryAdded(id)
        vaultChanged()
        _autoSave()
    }

    function updateEntry(id, fields) {
        if (!entries[id]) return
        for (const key in fields) {
            if (key !== "id" && key !== "created") {
                entries[id][key] = fields[key]
            }
        }
        entries[id].modified = Date.now()
        if (fields.category) _ensureCategory(fields.category)
        _refreshDisplay()
        entryUpdated(id)
        vaultChanged()
        _autoSave()
    }

    function deleteEntry(id) {
        if (!entries[id]) return
        delete entries[id]
        _refreshDisplay()
        entryDeleted(id)
        vaultChanged()
        _autoSave()
    }

    function getEntry(id) {
        return entries[id] || null
    }

    function getEntryByName(name) {
        const lower = name.toLowerCase()
        for (const id in entries) {
            if (entries[id].name.toLowerCase() === lower) {
                return entries[id]
            }
        }
        return null
    }

    function search(query) {
        searchQuery = query
        _refreshDisplay()
    }

    function filterByCategory(category) {
        selectedCategory = category
        _refreshDisplay()
    }

    function _refreshDisplay() {
        const result = []
        const query = searchQuery.toLowerCase().trim()

        for (const id in entries) {
            const entry = entries[id]

            if (selectedCategory !== "all" && entry.category !== selectedCategory) {
                continue
            }

            if (query) {
                const matchName = entry.name.toLowerCase().indexOf(query) !== -1
                const matchUser = entry.username.toLowerCase().indexOf(query) !== -1
                const matchUrl = entry.url.toLowerCase().indexOf(query) !== -1
                const matchNotes = entry.notes.toLowerCase().indexOf(query) !== -1

                if (!matchName && !matchUser && !matchUrl && !matchNotes) {
                    continue
                }
            }

            result.push(entry)
        }

        result.sort(function(a, b) {
            return a.name.toLowerCase().localeCompare(b.name.toLowerCase())
        })

        displayEntries = result
    }

    function _autoSave() {
        if (CryptoService.isUnlocked) {
            CryptoService.saveVault(toJSON())
        }
    }

    function _wipe() {
        entries = {}
        displayEntries = []
        searchQuery = ""
        selectedCategory = "all"
    }

    function _ensureCategory(cat) {
        for (let i = 0; i < categoryList.length; i++) {
            if (categoryList[i] === cat) return
        }
        categoryList = categoryList.concat([cat])
    }

    function _generateId() {
        return "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, function(c) {
            const r = Math.random() * 16 | 0
            const v = c === "x" ? r : (r & 0x3 | 0x8)
            return v.toString(16)
        })
    }
}
