pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

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
}
