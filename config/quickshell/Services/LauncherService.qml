pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    property var results: []
    property int selected_index: 0
    readonly property string web_search_prefix: "?"

    function is_math_expression(text) {
        return /^[0-9+\-*/(). %]+$/.test(text.trim())
    }

    function calculate(text) {
        try {
            const tokens = text.trim().match(/(\d+\.?\d*|[+\-*/()])/g)
            if (!tokens) return null
            let result = parse_expression(tokens, { pos: 0 })
            if (tokens.length > 0) return null
            return result
        } catch (e) {
            return null
        }
    }

    function parse_expression(tokens, state) {
        let left = parse_term(tokens, state)
        while (state.pos < tokens.length && (tokens[state.pos] === '+' || tokens[state.pos] === '-')) {
            const op = tokens[state.pos++]
            const right = parse_term(tokens, state)
            left = op === '+' ? left + right : left - right
        }
        return left
    }

    function parse_term(tokens, state) {
        let left = parse_factor(tokens, state)
        while (state.pos < tokens.length && (tokens[state.pos] === '*' || tokens[state.pos] === '/')) {
            const op = tokens[state.pos++]
            const right = parse_factor(tokens, state)
            left = op === '*' ? left * right : left / right
        }
        return left
    }

    function parse_factor(tokens, state) {
        if (state.pos >= tokens.length) throw new Error("unexpected end")
        let token = tokens[state.pos]
        if (token === '(') {
            state.pos++
            const result = parse_expression(tokens, state)
            if (state.pos < tokens.length && tokens[state.pos] === ')') state.pos++
            return result
        }
        if (token === '-') {
            state.pos++
            return -parse_factor(tokens, state)
        }
        if (token === '+') {
            state.pos++
            return parse_factor(tokens, state)
        }
        state.pos++
        return parseFloat(token)
    }

    function fuzzy_match(query, target) {
        if (query.length === 0) return true
        let qi = 0
        for (let ti = 0; ti < target.length && qi < query.length; ti++) {
            if (target[ti] === query[qi]) qi++
        }
        return qi === query.length
    }

    function filter(text) {
        const raw = text.trim()
        const query = raw.toLowerCase()

        if (raw.length === 0) {
            results = []
            selected_index = 0
            return
        }

        const prefix = web_search_prefix
        const force_web_search = raw.startsWith(prefix)

        const app_query = force_web_search
            ? query.substring(prefix.length)
            : query

        const found = []
        let application_count = 0

        if (is_math_expression(raw)) {
            const result = calculate(raw)
            if (result !== null) {
                found.push({
                    type: "calculation",
                    icon: "equal",
                    name: `${result}`,
                    value: result
                })
            }
        }

        const apps = DesktopEntries.applications.values
        const fuzzy_results = []

        for (let i = 0; i < apps.length; i++) {
            const app = apps[i]
            if (!app) continue

            const name = (app.name || "").toLowerCase()
            const generic_name = (app.genericName || "").toLowerCase()

            if (name.includes(app_query) || generic_name.includes(app_query)) {
                found.push({
                    type: "application",
                    icon: "chevron_forward",
                    name: app.name,
                    app: app
                })
                application_count++
                if (application_count >= 8) break
            } else if (fuzzy_match(app_query, name) || fuzzy_match(app_query, generic_name)) {
                fuzzy_results.push({
                    type: "application",
                    icon: "chevron_forward",
                    name: app.name,
                    app: app
                })
            }
        }

        for (let i = 0; i < fuzzy_results.length && application_count < 8; i++) {
            found.push(fuzzy_results[i])
            application_count++
        }

        if (force_web_search) {
            found.unshift({
                type: "websearch",
                icon: "search",
                name: `Search for "${raw.substring(prefix.length)}"`,
                query: raw.substring(prefix.length)
            })
        } else if (application_count < 3) {
            found.push({
                type: "websearch",
                icon: "search",
                name: `Search for "${raw}"`,
                query: raw
            })
        }

        results = found
        selected_index = 0
    }

    function select_next() {
        if (results.length > 0)
            selected_index = (selected_index + 1) % results.length
    }

    function select_prev() {
        if (results.length > 0)
            selected_index = (selected_index - 1 + results.length) % results.length
    }

    function clear() {
        results = []
        selected_index = 0
    }
}
